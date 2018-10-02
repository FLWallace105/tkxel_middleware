class LogTrail < ApplicationRecord

  belongs_to :logtrailable, polymorphic: true , optional: true
  belongs_to :brand

  enum status: [:received_from_shopify, :pushed_to_cims , :cims_push_failed, :inventory_updated_on_shopify ,:fulfilled ,:inventory_updated_locally,:inventory_update_failed_on_shopify ,:inventory_update_failed_locally , :partially_fulfilled]
  enum trigger_type: [:webhook, :cron_job , :cims_manual_sync]

  scope :fail_order_tries, -> (brand_ids){ where(status: LogTrail.statuses[:cims_push_failed],brand_id: brand_ids, created_at: (Time.now - 7.days)..Time.now)}

  after_save :update_order_status

  def update_order_status
    if self.logtrailable_type == "Order"
      order = Order.find(self.logtrailable_id)
      order.update(status: self.status)
    end
  end

end
