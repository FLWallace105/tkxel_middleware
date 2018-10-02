class Order < ApplicationRecord
  # after_save :log_entry , :process_order
  belongs_to :brand
  has_many :log_trails, as: :logtrailable, dependent: :destroy
  delegate :warehouse_code, :shop_name, :vendor_name, :udf4, to: :brand
  validates_uniqueness_of :name, :tracking_id
  attr_accessor :trigger_type
  enum status: [:received_from_shopify, :pushed_to_cims , :cims_push_failed, :inventory_updated_on_shopify ,:fulfilled ,:inventory_updated_locally,:inventory_update_failed_on_shopify ,:inventory_update_failed_locally , :partially_fulfilled]


  scope :fail_orders,-> (brand_ids) { where(status: Order.statuses[:cims_push_failed] , brand_id: brand_ids) }
  scope :success_orders,-> (brand_ids, log_statuses = Order.statuses.values - [Order.statuses[:cims_push_failed]]) { where(status: log_statuses , brand_id: brand_ids) }
  scope :fetch_by_pick_ticket, -> (pick_tickets) {where(tracking_id: pick_tickets) }
  scope :failed_orders,-> { where(status: Order.statuses[:cims_push_failed]) }


  store_accessor :details, :total_price, :customer, :line_items, :tags

  def log_status
    log_trails.last.status
  end

  def log_last_sync
    log_trails.last.updated_at
  end

  def log_trigger_type
    log_trails.last.trigger_type
  end

  # def customer_name
  #   customer['first_name']+ " " +customer['last_name']
  # end

  def created_date
    details["created_at"].to_date.strftime("%m/%d/%Y")
  end

  def order_type
    shop_name == ENV['ELLIE_SHOP_NAME'] ? 'V' : 'W'
  end

  def self.new_order_from_json(order_json, shop_name)
    order = JSON.parse(order_json)
    brand_id = Brand.find_by_name(shop_name).id
    new(name: order['name'],
        tracking_id: order['id'],
        price: order['total_price'],
        customer_name: order['customer']['first_name']+ " " +order['customer']['last_name'],
        details: order,
        brand_id: brand_id
    )
  end

  def tax_rate
    tax_rate = details['tax_lines'].map {|s| s["rate"].present? ? s["rate"] : 0 }.reduce(0, :+)
    tax_rate.round(4)
  end


  def ship_via
    begin
      case details['shipping_lines'][0]['title']
        when 'Free Shipping (5-9 days)'
          code = 'BESTGND'
        when 'Free Shipping (7-10 Days)'
          code = 'BESTGND'
        when 'Standard Shipping (6-9 days)'
          code = 'BESTGND'
        when 'Standard Shipping (5-9 Days)'
          code = 'BESTGND'
        when 'Overnight'
          code = 'BEST1DAY'
        when 'Overnight Shipping'
          code = 'BEST1DAY'
        when 'Expedited Shipping'
          code = 'BEST1DAY'
        when  '2nd Day Air'
          code = 'BEST2DAY'
        when 'Express Shipping (1-2 days)'
          code = 'BEST2DAY'
        when  'International Shipping'
          code = 'BESTINT'
        else
          code = 'BESTGND'
      end
    rescue => ex
      code = 'BESTGND'
    end
    code
  end
  def self.new_order_from_hash(order_hash, shop_name)
    brand_id = Brand.find_by_name(shop_name).id
    new(name: order_hash.name,
        tracking_id: order_hash.id,
        price: order_hash.total_price,
        customer_name: ((order_hash.customer.first_name+ " " +order_hash.customer.last_name) rescue ""),
        details: order_hash,
        brand_id: brand_id
    )
  end

  def is_ellie_order?
    shop_name == ENV['ELLIE_SHOP_NAME'] ? true : false
  end

  def is_composite_product?(line_item)
    product_collection_title = line_item['properties'].select {|property| property['name'] == 'product_collection'}
    product_collection_title.present?  ? (product_collection_title.first['value'].length > 0) : false
  end

  def get_collection_title(line_item)
    line_item['properties'].select {|property| property['name'] == 'product_collection'}.first['value']
  end

  def get_products_for_collection(collection_title)
    #init shopify with brand before using this method
    ShopifyAPI::CustomCollection.where(title: collection_title).first.products
  end

  def get_child_skus_from_collection
    if is_ellie_order?
      child_items = []
      parent_items = []
      Shopify.new(ENV['ELLIE_SHOP_NAME'])
      line_items.each do |line_item|
        if is_composite_product?(line_item)
          collection_tittle = get_collection_title(line_item)
          if collection_tittle.present?
            products = get_products_for_collection(collection_tittle)
            products.each do |product|
              unless ELLIE_ACCESSORIES.map{ |p| p.gsub(/\W/,"").downcase }.include? product.product_type.gsub(/\W/,"").downcase
                line_item_size = line_item['properties'].select{|property| property['name'].gsub(/\W/,"").downcase == product.product_type.gsub(/\W/,"").downcase }.first['value']
                product_variant = product.variants.select{ |f| f.title.downcase == line_item_size.downcase}
              else
                product_variant = product.variants
              end
              product_variant = product_variant.map{ |temp_variant| temp_variant.attributes.merge!({"quantity"=> line_item['quantity'], "product_id"=>line_item['product_id']}) }
              child_items = child_items + product_variant
            end
            parent_items << line_item.merge!("composite_product" => true)
          end
        else
          parent_items << line_item
        end
      end
      {parents: parent_items, childs: child_items}
    else
      {parents: self.line_items, childs: []}
    end
  end

  def self.get_all_subscriptions
    ReCharge.api_key = ENV['ellie_recharge_api_key']
    all_subscriptions = []
    page=1
    loop do
      subscriptions = ReCharge::Subscription.list(limit: 250, page: page, status: "ACTIVE")
      if subscriptions.count == 0
        break
      else
        all_subscriptions = all_subscriptions + subscriptions
        page+=1
      end
    end
    all_subscriptions
  end

  def import_to_cims(line_items , brand_id, trigger_type)
    xml_generate_status , message_body = CIMS.get_import_records(line_items, self)
    response_status = (xml_generate_status.present? ? CIMS.post_records_to_cims(message_body,brand_id,self) : message_body)
    status = (response_status == true ? LogTrail.statuses[:pushed_to_cims] : LogTrail.statuses[:cims_push_failed])
    log_entry(trigger_type, status,response_status)
  end

  def save_order(trigger_type, status)
    if self.save!
      log_entry(trigger_type, status)
      process_order(trigger_type)
    end
  end


  def log_entry(trigger_type, status , description ='')
    self.log_trails.create!(trigger_type: trigger_type,
                            status: status, brand_id: brand_id,description: description )
  end


  def adjust_ellie_inventory_for_composite_product(items, trigger_type)
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    if items[:childs].any? && tags.include?(ELLIE_SUBSCRIPTION_FIRST_ORDER_TAG)
      begin
        items[:childs].each do |variant|
          ShopifyAPI::InventoryLevel.where(inventory_item_ids: variant['inventory_item_id']).first.adjust(-(variant['quantity']))
        end
        log_entry(trigger_type, LogTrail.statuses[:inventory_updated_on_shopify])
      rescue => exception
        log_entry(trigger_type,LogTrail.statuses[:inventory_update_failed_on_shopify], exception)
        ErrorService.notify_brand_users_utility(brand_id,exception,'Inventory update failed on shopify')
      end
    elsif items[:childs].any? && tags.include?(ELLIE_SUBSCRIPTION_RECURING_ORDER_TAG)
      begin
        items[:childs].each do| variant|
          ReserveInventory.where(variant_sku: variant['sku'],product_id: variant['product_id']).first.increment!(:delivered_count)
        end
        log_entry(trigger_type, LogTrail.statuses[:inventory_updated_locally])
      rescue => exception
        log_entry(trigger_type,LogTrail.statuses[:inventory_update_failed_locally], exception)
        ErrorService.notify_brand_users_utility(brand_id,exception,'Inventory update failed locally')
      end
    end
  end

  def process_order(trigger_type)
    items = self.get_child_skus_from_collection
    if is_ellie_order?
      adjust_ellie_inventory_for_composite_product(items,trigger_type)
    end
    import_to_cims(items, self.brand_id,trigger_type)
  end
end
