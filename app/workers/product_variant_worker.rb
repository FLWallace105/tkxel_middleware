require 'rubygems'
require 'shopify_api'

class ProductVariantWorker
  include Sidekiq::Worker

  JOB_NAME = 'ProductVariantAddWorker'

  sidekiq_options backtrace: true

  sidekiq_retries_exhausted do |ctx, ex|
    Sidekiq.logger.warn "Failed #{ctx['class']} with #{ctx['args']}: #{ctx['error_message']}"
    ErrorService.notify(ex,ctx)
  end

  def perform(brand_name)
      brand = Brand.find_by_name(brand_name)
      Shopify.new(brand.name)
      inventory_response = CIMS.fetch_inventory_on_hand(brand.id, brand.
          warehouse_code)
      skus = inventory_response.pluck(:upc)
      last_lync = brand.last_runned_at(JOB_NAME)
      page = 1
      loop do
        products = ShopifyAPI::Product.find(:all, params: {limit: 250, page: page , updated_at_min: last_lync})
        break if products.empty?
        products.each do |product|
          product.variants.each do |variant|
            log_entry = brand.inventory_logs.create(sku: variant.sku,
                                         shopify_variant: variant.id,
                                         product_id: product.id,
                                         name: variant.title)

            if log_entry.persisted? && !skus.include?(variant.sku)
                brand.
                    inventory_on_hands.
                    create(sku: variant.sku,
                           threshold_percentage: 0, status: FAIL_INVENTORY_STATUS_FOR_CIMS)
            end
          end
        end
        page = page + 1
        wait_for_shopify_credits
      end
      brand.jobs.create!(name: JOB_NAME ,runned_at: Time.now)

  end

  private

  def wait_for_shopify_credits
    if ShopifyAPI::credit_left < 4
      puts "sleeping for 10 seconds to obtain credits..."
      sleep(10)
    else
      puts "credit limit left #{ShopifyAPI::credit_left}"
    end
  end

end
