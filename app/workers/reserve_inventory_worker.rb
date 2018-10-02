require 'rubygems'
require 'shopify_api'

class ReserveInventoryWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  JOB_NAME = "ReserveInventoryJob"

  def perform
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    brand = Brand.find_by_name(ENV['ELLIE_SHOP_NAME'])
    default_product = Product.get_main_default_product

    product = ShopifyAPI::Product.find(:all, params:{ids: default_product}).first
    collection = ShopifyAPI::CustomCollection.find(:all, params: { title: product.title }).first
    puts collection.inspect
    collection_products = collection.products
    reserve_inventory = ReserveInventory.get_reserve_inventory_with_sku.first

    reserve_inventory.each do |product_type, sizes|

      selected_product = collection_products.select {|product| product.product_type.downcase.gsub(/\W/, "") == product_type}.first
      unless selected_product.present?
        next
      end
      sizes.each do |size, size_count|
        product_variant = selected_product.variants.select {|f| f.title.downcase == size.downcase}.first

        unless product_variant.present?
            next
        end

        puts "*************product*******************"
        puts product_type
        puts size,size_count
        puts product_variant.inspect
        puts product_variant.inventory_item_id
        puts product_variant.sku
        puts collection.title
        puts selected_product.product_type
        puts "********************************"

        status = ShopifyAPI::InventoryLevel.all(params: {inventory_item_ids: product_variant.inventory_item_id}).first.adjust(size_count * -1)
        if status
          ReserveInventory.create(product_id: product.id, product_type: product_type, size: size, size_count: size_count , collection_id: collection.id , collection_name: collection.title, brand_id: brand.id, variant_sku: product_variant.sku, inventory_item_id: product_variant.inventory_item_id)
        end
      end

    end
    brand.jobs.create!(name: JOB_NAME ,runned_at: Time.now)
  end

end
