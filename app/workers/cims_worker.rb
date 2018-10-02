require 'rubygems'
require 'savon'
require 'csv'
require 'benchmark'
class CimsWorker

  include Sidekiq::Worker
  sidekiq_options backtrace: true


  sidekiq_retries_exhausted do |ctx, ex|
    Sidekiq.logger.warn "Failed #{ctx['class']} with #{ctx['args']}: #{ctx['error_message']}"
    ErrorService.notify(ex, ctx)
  end

  def perform(job_to_do, selected_brand_names)
    selected_brands = Brand.brand_ids(selected_brand_names)
    case job_to_do
      when SIDEKIQ_JOB_IMPORT

        fail_orders = Order.fail_orders(selected_brands)
        fail_orders.each do |fo|
          fo.import_to_cims(fo.get_child_skus_from_collection, fo.brand_id, LogTrail.
              trigger_types[:cims_manual_sync])
        end
        selected_brands.each {|brand_id| Job.create(name: IMPORT_JOB_NAME,
                                                    brand_id: brand_id, runned_at: Time.now)}
      when SIDEKIQ_JOB_FULFILLMENT

        Fulfillment.where("created_at <= (?)", Time.now - 7.days).destroy_all
        Brand.where(id: selected_brands).each do |brand|
          job = brand.jobs.new(name: FULFILLMENT_JOB_NAME)
          Shopify.new(brand.name)
          fully_fulfilled_pick_tickets, partial_fulfilled_hash_array = CIMS.
              fetch_fulfillment_data(brand.id,
                                     brand.vendor_name,
                                     job)

          # Work for Partially fulfilled orders

          partial_fulfilled_pick_tickets = partial_fulfilled_hash_array.pluck(:pick_ticket)
          partial_fulfilled_skus = partial_fulfilled_hash_array.pluck(:sku)
          partial_fulfilled_ref_ids = partial_fulfilled_hash_array.pluck(:ref_id)
          partial_fulfilled_pick_tickets.each_with_index do |order_id, index|
            order = Order.find_by_tracking_id(order_id)
            shopify_partial_order = ShopifyAPI::Order.find(order.tracking_id) if order.present? rescue nil
            if shopify_partial_order.present?
              item = order.line_items.detect {|item| item["sku"]==
                  partial_fulfilled_skus[index]}
              if item.present?
                fulfillment = mark_partially_fulfillment(shopify_partial_order.id, partial_fulfilled_ref_ids[index], item['id'])
                fulfillment.save
                order.log_trails.create(trigger_type: LogTrail.trigger_types[:cron_job],
                                        status: LogTrail.statuses[:partially_fulfilled],
                                        brand_id: brand.id,
                                        description: "Line item #{item['id']} has been fulfilled")

              end
            else
              brand.fulfillments.create(pick_ticket: order_id,
                                        status: NON_FULFILLED_ORDER)
            end
            wait_for_shopify_credits
          end

          # Work for fully fulfilled orders

          fully_fulfilled_orders = Order.fetch_by_pick_ticket(fully_fulfilled_pick_tickets)
          fully_fulfilled_order_ids = fully_fulfilled_orders.map(&:tracking_id)
          fully_fulfilled_orders.each do |order|
            shopify_order = ShopifyAPI::Order.find(order.tracking_id) rescue nil
            if shopify_order.present?
              fulfillment = mark_fully_fulfillment(shopify_order.id.to_i)
              fulfillment.save
              order.log_trails.create(trigger_type: LogTrail.trigger_types[:cron_job],
                                      status: LogTrail.statuses[:fulfilled],
                                      brand_id: brand.id,
                                      description: '')


            else
              brand.fulfillments.create(pick_ticket: order.tracking_id,
                                        status: NON_FULFILLED_ORDER)
            end
            wait_for_shopify_credits
          end
          (fully_fulfilled_pick_tickets - fully_fulfilled_order_ids).each {|order_id|
            brand.fulfillments.create(pick_ticket: order_id, status: NON_FULFILLED_ORDER)}
          job.runned_at = Time.now
          job.save!
        end

      when SIDEKIQ_JOB_INVENTORY

        InventoryOnHand.where("created_at <= (?)", Time.now - 7.days).destroy_all
        update_inventory_csv = CSV.generate do |csv|
          csv << ['SKU', 'Brand', 'Threshold %', 'Status']
          Brand.where(id: selected_brands).each do |brand|
            Shopify.new(brand.name)
            inventory_response = CIMS.fetch_inventory_on_hand(brand.id, brand.warehouse_code)
            if inventory_response.any?
              product_ids = brand.inventory_logs.select(:product_id).map(&:product_id).uniq
              product_ids.each do |id|
                wait_for_shopify_credits
                begin
                  product = ShopifyAPI::Product.find(id)
                rescue => exception
                  next
                end
                product.variants.each do |variant|
                  record = inventory_response.select{|records| records[:upc]== variant.sku}.first
                  if record.present?
                    unless brand.name == ENV['ELLIE_SHOP_NAME']
                      percentage = ((record[:onhand_available_qty].to_i - variant.inventory_quantity)/variant.inventory_quantity * 100) rescue 100
                      puts variant.inventory_quantity
                      variant.inventory_quantity = record[:onhand_available_qty].to_i
                      puts variant.inventory_quantity
                    else
                      #adjust reserve quantity before setting on shopify
                      reserved_quantity = brand.reserve_inventories.where(variant_sku: variant.sku)
                      final_quantity = (record[:onhand_available_qty].to_i) - (reserved_quantity.sum(:size_count) - reserved_quantity.sum(:delivered_count))
                      percentage = ((final_quantity - variant.inventory_quantity)/variant.inventory_quantity * 100) rescue 100
                      puts variant.inventory_quantity
                      variant.inventory_quantity = final_quantity
                      puts variant.inventory_quantity
                    end
                  else
                    puts variant.inventory_quantity
                    variant.inventory_quantity = 0
                    puts variant.inventory_quantity
                    percentage = 0
                  end
                  brand.inventory_on_hands.where(sku: variant.sku).destroy_all
                  log = brand.inventory_on_hands.create!(sku: variant.sku, threshold_percentage: percentage, status: "#{percentage}" + INVENTORY_CHANGE)
                  csv << [log.sku, brand.name, "#{percentage.to_i}", log.status]
                end
                wait_for_shopify_credits
                product.save!
              end
            end
            brand.jobs.create!(name: UPDATE_INVENTORY_JOB_NAME, runned_at: Time.now)
          end
        end
        ErrorService.notify_inventory_breach_utility(selected_brands, update_inventory_csv)
    end
  end

  private

  def mark_partially_fulfillment(order_id, ref_id, line_item)
    fulfillment = ShopifyAPI::Fulfillment.new(:order_id => order_id,
                                              :tracking_number => ref_id,
                                              :tracking_company => ship_via_for_shopify(ref_id.to_s),
                                              :line_items => [id: line_item.to_i],
                                              :notify_customer => true)
    fulfillment.prefix_options = {:order_id => order_id}
    fulfillment
  end

  def mark_fully_fulfillment(order_id)
    fulfillment = ShopifyAPI::Fulfillment.new(:order_id => order_id,
                                              :notify_customer => true)
    fulfillment.prefix_options = {:order_id => order_id}
    fulfillment
  end


  def wait_for_shopify_credits
    if ShopifyAPI::credit_left < 4
      puts "sleeping for 10 seconds to obtain credits..."
      sleep(10)
    else
      puts "credit limit left #{ShopifyAPI::credit_left}"
    end
  end

  def ship_via_for_shopify(ref_id)
    case ref_id[0..2]
      when '940'
        via = 'USPS'
      when '612'
        via = 'FEDEXSP'
      when '405'
        via = 'FEDEX'
      when '737'
        via = 'FEDEX'
      when '165'
        via = 'APC'
      else
        via = 'Carrier Not Found'
    end
    via
  end

  # def update_zero_inventory_on_shopify(items_with_zero_inventory,brand)
  #   Shopify.new(brand.name)
  #   items_with_zero_inventory.each do |inventory_item|
  #     shopify_variant = ShopifyAPI::Variant.find(inventory_item.shopify_variant) rescue nil
  #     if shopify_variant.present?
  #       brand.inventory_on_hands.where(sku: inventory_item.sku).destroy_all
  #       unless shopify_variant.inventory_quantity == 0
  #         shopify_variant.inventory_quantity = 0
  #         shopify_variant.save!
  #         log = brand.inventory_on_hands.create(sku: shopify_variant.sku,threshold_percentage: 0, status: OUT_OF_STOCK)
  #       end
  #     else
  #       brand.inventory_on_hands.create(sku: inventory_item.sku, threshold_percentage: 0, status: FAIL_INVENTORY_STATUS)
  #     end
  #     wait_for_shopify_credits
  #   end
  # end

end
