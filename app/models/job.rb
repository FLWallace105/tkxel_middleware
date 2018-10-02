class Job < ApplicationRecord
  belongs_to :brand

  scope :order_last_sync, -> (brand_ids){ where(brand_id: brand_ids,
                                                name: ['OrderJob', IMPORT_JOB_NAME]).last.
      created_at.strftime('%^b %d,%Y %H:%m') rescue Time.now.strftime('%^b %d,%Y %H:%m')  }
  scope :inventory_last_sync, -> (brand_ids){ where(brand_id: brand_ids,name: UPDATE_INVENTORY_JOB_NAME).last.created_at.strftime('%^b %d,%Y %H:%m') rescue Time.now.strftime('%^b %d,%Y %H:%m') }

  def self.is_current_month_inventory_reserved
    jobs = where("name = ? AND runned_at >= ? AND runned_at <= ?","ReserveInventoryJob",Date.today.at_beginning_of_month,Date.today.at_end_of_month)
    jobs.first.present? ? true : false
  end

end
