class InventoryOnHand < ApplicationRecord
  belongs_to :brand
  delegate :name, to: :brand ,  prefix: true
  # validates_uniqueness_of :sku
  validates_uniqueness_of :sku, :scope => [:brand_id]

  scope :fail_inventory,-> (brand_ids) {where(brand_id: brand_ids, created_at: (Time.now - 7.days)..(Time.now)).order('created_at DESC')}
end
