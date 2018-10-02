class InventoryLog < ApplicationRecord
  belongs_to :brand
  validates_uniqueness_of :sku,scope: :shopify_variant
  validates_uniqueness_of :shopify_variant , scope: :brand_id

  def self.save_variants_inventory(product_json,shop_name)
    product = JSON.parse(product_json)
    brand = Brand.find_by_name(shop_name)
    product["variants"].each do |variant|
      brand.inventory_logs.create(sku: variant['sku'], shopify_variant: variant['id'],product_id: product['id'], name: variant['title'])
    end
  end

end
