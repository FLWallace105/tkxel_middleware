class Fulfillment < ApplicationRecord
  belongs_to :brand
  delegate :name, to: :brand ,  prefix: true

  scope :fail_fulfillment,-> (brand_ids) {where(brand_id: brand_ids, created_at: (Time.now - 7.days)..(Time.now)).order('created_at DESC')}
end
