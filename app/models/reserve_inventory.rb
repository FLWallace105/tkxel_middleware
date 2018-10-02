class ReserveInventory < ApplicationRecord
  include ShopifyConnection
  belongs_to :brand
  has_many :inventory_trails
  # validates_uniqueness_of :inventory_item_id , scope: :collection_id

  scope :current_month,-> {where("created_at >= ? AND created_at <= ?",Date.today.at_beginning_of_month,Date.today.at_end_of_month).order('collection_id DESC,product_type DESC,size DESC')}

  def self.get_all_subscriptions
    ReCharge.api_key = ENV['ellie_recharge_api_key']
    all_subscriptions = []
    page=1
    loop do
      subscriptions = ReCharge::Subscription.list(limit: 250,page: page,status:"ACTIVE")
      if subscriptions.count == 0
        break
      else
        all_subscriptions = all_subscriptions + subscriptions
        page+=1
      end
    end
    all_subscriptions
  end

  def self.is_current_month_subscription?(subscription)
    !subscription.next_charge_scheduled_at.nil? && subscription.next_charge_scheduled_at.to_date > Date.today && subscription.next_charge_scheduled_at.to_date < Date.today.end_of_month
  end

  def self.get_reserve_inventory_old #old method,now merged in function below
    product_types_with_sizes = []
    all_subscriptions = ReserveInventory.get_all_subscriptions
    product_types= ELLIE_PRODUCT_TYPES.map{ |p| p.gsub(/\W/,"").downcase }

    product_types.each do |product_type|
      all_subscriptions.each do |subscription|
        if ReserveInventory.is_current_month_subscription?(subscription)
          select_product_type = subscription.properties.select{ |property| property['name'].gsub(/\W/,"").downcase == product_type }.first || next
          product_types_with_sizes << select_product_type
        end
      end
    end
    group_by_product_type = product_types_with_sizes.group_by{ |product| product['name'].gsub(/\W/,"").downcase }
    size_counts = Hash.new
    product_types.each do |product_type|
      group_by_size = group_by_product_type[product_type] || next
      size_counts[product_type] = group_by_size.group_by{|r| r['value']}.inject({}) do |hash, (k,v)|
        hash[k] = v.size
        hash
      end
    end
    size_counts
  end

  def self.get_reserve_inventory_with_sku
    product_types_with_sizes = []
    all_subscriptions = get_all_subscriptions
    product_types = ELLIE_PRODUCT_TYPES.map {|p| p.gsub(/\W/, "").downcase}

    product_types.each do |product_type|
      all_subscriptions.each do |subscription|
        if ReserveInventory.is_current_month_subscription?(subscription)
          select_product_type = subscription.properties.select{ |property| property['name'].gsub(/\W/,"").downcase == product_type }.first || next
          product_types_with_sizes << select_product_type.merge!("shopify_product_id" => subscription.shopify_product_id,"tittle" => subscription.product_title)
        end
      end
    end

    group_by_sku = product_types_with_sizes.group_by{ |product| [product['shopify_product_id'] ]  }
    size_counts = Hash.new
    size_counts_with_sku = Hash.new

    group_by_sku.each do |key, value|
      size_counts_with_sku[key] = []
      group_by_product_type = value.group_by {|product| product['name'].gsub(/\W/,"").downcase}
      product_types.each do |product_type|
        temp_size_counts = Hash.new
        group_by_size = group_by_product_type[product_type] || next
        temp_size_counts[product_type] = group_by_size.group_by {|r| r['value'].downcase}.inject({}) do |hash, (k, v)|
          hash[k] = v.size
          hash
        end
        size_counts_with_sku[key] << temp_size_counts
      end
    end


    group_by_product_type = product_types_with_sizes.group_by{ |product| product['name'].gsub(/\W/,"").downcase }
    size_counts = Hash.new
    product_types.each do |product_type|
      group_by_size = group_by_product_type[product_type] || next
      size_counts[product_type] = group_by_size.group_by{|r| r['value'].downcase}.inject({}) do |hash, (k,v)|
        hash[k] = v.size
        hash
      end
    end

    [size_counts ,size_counts_with_sku]

  end

  def self.get_current_month_products_from_shopify
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    ShopifyAPI::Product.find(:all, params: { ids: Product.get_current_month_products_ids })
  end

  def self.update_default_product_inventory(size, product_type, product_id,size_count)
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    wait_for_shopify_credits
    variant = ReserveInventory.where(product_id: product_id, product_type: product_type, size: size)
    if variant.first.present?
      variant = variant.first
      variant_size_count = size_count + variant.delivered_count
      adjustment = variant.size_count - variant_size_count
      if adjustment != 0
        status = ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: variant.inventory_item_id}).first.adjust(adjustment)
        puts "*************default product*******************"
        puts "SHOPIFY = #{variant.product_id}-#{product_type}-#{size}-#{size_count}-#{adjustment}"
        variant.size_count = size_count + variant.delivered_count
        variant.save!
        puts "local db = #{variant.product_id}-#{product_type}-#{size}-#{size_count}-UPDATEDVALUE"
      end
      adjustment = 0
    else
      brand = Brand.find_by_name(ENV['ELLIE_SHOP_NAME'])
      product = Product.where(product_id: product_id).first
      if product.present?
        collection = ShopifyAPI::CustomCollection.find(:all, params: { title: product.product_title }).first
        collection_products = collection.products
        selected_product = collection_products.select {|product| product.product_type.downcase.gsub(/\W/, "") == product_type}.first
        if selected_product.present?
          product_variant = selected_product.variants.select {|f| f.title.downcase == size.downcase}.first
          variant = ReserveInventory.new(product_id: product.product_id, product_type: product_type, size: size, size_count: size_count , collection_id: collection.id , collection_name: collection.title, variant_sku: product_variant.sku, inventory_item_id: product_variant.inventory_item_id,brand_id: brand.id)
          variant.save!
          puts "local db = #{product.product_id}-#{product_type}-#{size}-#{size_count}-NEWLYADDED"
          ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: variant.inventory_item_id}).first.adjust(-size_count)
        end
      end
    end
  end

  def self.update_null_sizes null_sizes_hash
    null_sizes_hash.each do |sku, product_sizes|
      product_sizes.each do |product_type,size_counts|
        size_counts.each do |size,count|
          wait_for_shopify_credits
          if count == 0
            variants = ReserveInventory.where(product_id: sku, product_type: product_type, size: size)
            variant_size_count = variants.sum(:size_count) - variants.sum(:delivered_count)
            if variant_size_count !=0
              status = ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: variants.first.inventory_item_id}).first.adjust(variant_size_count)
              puts "##############update null sizes##############"
              puts "SHOPIFY = #{sku}-#{product_type}-#{size}-#{count}-#{}"
              variants.update_all(size_count: 0)
              puts "local db = #{sku}-#{product_type}-#{size}-0-UPDATEDVALUE"
            end
          end
        end
      end
    end
  end

  def self.update_reserve_inventory
    current_month_products_id = Product.get_current_month_products_ids
    default_product_ids = Product.get_default_product_ids
    default_inventory = ReserveInventory.get_reserve_inventory_with_sku
    reserve_inventory_orignal = default_inventory.first
    reserve_inventory_with_sku = default_inventory.last
    brand = Brand.find_by_name(ENV['ELLIE_SHOP_NAME'])
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    reserve_inventory = Hash.new
    puts "********************************"
    puts "SOURCE = SKU-TYPE-SIZE-SIZECOUNT-ADJUSTMENT"
    reserve_inventory_with_sku.each do |key,value|
      product_id = key.first
      temp = Hash.new
      temp[product_id] = {}
      value.each do |product_sizes|

        product_sizes.each do |product_type,sizes|
          temp[product_id][product_type] = {}
          temp[product_id][product_type]["s"] = 0
          temp[product_id][product_type]["m"] = 0
          temp[product_id][product_type]["l"] = 0
          temp[product_id][product_type]["xl"] = 0
          temp[product_id][product_type]["xs"] = 0

          sizes.each do |size,size_count|
            if size == ""
              next
            end
            wait_for_shopify_credits
            if current_month_products_id.include?(product_id) && !(default_product_ids.include?(product_id))
              temp[product_id][product_type][size] = size_count
              variant = ReserveInventory.where(size: size, product_type: product_type, product_id: product_id)
              product = Product.where(product_id: product_id).first
              if variant.first.present?
                variant = variant.first
                variant_size = size_count + variant.delivered_count
                adjustment = variant.size_count - variant_size
              else
                collection = ShopifyAPI::CustomCollection.find(:all, params: { title: product.product_title }).first
                collection_products = collection.products
                selected_product = collection_products.select {|product| product.product_type.downcase.gsub(/\W/, "") == product_type}.first
                unless selected_product
                  next
                end
                product_variant = selected_product.variants.select {|f| f.title.downcase == size.downcase}.first
                variant = ReserveInventory.new(product_id: product.product_id, product_type: product_type, size: size, size_count: size_count , collection_id: collection.id , collection_name: collection.title, variant_sku: product_variant.sku, inventory_item_id: product_variant.inventory_item_id,brand_id:brand.id)
                variant.save!
                puts "local db = #{product.product_id}-#{product_type}-#{size}-#{size_count}-NEWLYADDED"
                ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: variant.inventory_item_id}).first.adjust(-size_count)
                adjustment = variant.size_count - size_count
                puts "SHOPIFY = #{product.product_id}-#{product_type}-#{size}-#{size_count}-#{-size_count}"
              end
              if adjustment !=0
                status = ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: variant.inventory_item_id}).first.adjust(adjustment)
                puts "SHOPIFY = #{product.product_id}-#{product_type}-#{size}-#{size_count}-#{adjustment}"
                variant.size_count = size_count + variant.delivered_count
                variant.save!
                puts "local db = #{product.product_id}-#{product_type}-#{size}-#{size_count}-UPDATEDVALUE"
              end
            else


              ReserveInventory.update_default_product_inventory(size, product_type, product_id,size_count)
              # if reserve_inventory[product_type].nil?
              #   reserve_inventory[product_type] = {}
              #   reserve_inventory[product_type][size] = 0
              # elsif reserve_inventory[product_type][size].nil?
              #   reserve_inventory[product_type][size] = 0
              # end
              # reserve_inventory[product_type][size] =  size_count + reserve_inventory[product_type][size]
            end
            adjustment = 0
          end
          if current_month_products_id.include?(product_id) && !(default_product_ids.include?(product_id))
            ReserveInventory.update_null_sizes temp
          end
          temp[product_id] = {}
        end
      end
    end
  end
end
