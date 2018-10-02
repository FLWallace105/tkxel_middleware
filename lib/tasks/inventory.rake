require 'rubygems'

JOB_NAME = 'ProductVariantAddWorker'

namespace :inventory do
  desc "Populate Inventory for first time to have variants"
  task :populate_inventory => :environment do
    Brand.each do |brand|
        Shopify.new(brand.name)
        page = 1
        loop do
          variants = ShopifyAPI::Variant.find(:all, params: {limit: 250, page: page})
          break if variants.empty?
          variants.each do |variant|
            brand.inventory_logs.create(sku: variant.sku, shopify_variant: variant.id, product_id: variant.product_id,name: variant.title)
          end
          page = page + 1
        end
        brand.jobs.create!(name: JOB_NAME ,runned_at: Time.now)
    end
  end
end