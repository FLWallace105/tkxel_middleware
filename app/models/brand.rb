class Brand < ApplicationRecord
  validates_uniqueness_of :name
  has_many :user_brands , dependent: :destroy
  has_many :orders , dependent: :destroy
  has_many :users, through: :user_brands
  has_many :jobs , dependent: :destroy
  has_many :fulfillments , dependent: :destroy
  has_many :inventory_on_hands , dependent: :destroy
  has_many :inventory_logs, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :reserve_inventories, dependent: :destroy
  accepts_nested_attributes_for :products, reject_if: :all_blank, allow_destroy: true
  scope :brand_names, -> (brand_ids) { where(id: brand_ids).map(&:name)}
  scope :brand_ids, -> (brand_names) { where(name: brand_names).map(&:id)}
  scope :brand_names_string, -> (brand_ids) {brand_names(brand_ids).join(',').titleize}
  def last_runned_at(job_name)
    jobs.where(name: job_name).order(created_at: :desc).first.runned_at.utc.to_time.iso8601 rescue Time.now.utc.to_time.iso8601
  end


  def active_users
    users.where(deleted_at: nil).where.not(confirmed_at: nil)
  end

  def shop_name
    name
  end

  def warehouse_code
    case name
      when ENV['MARIKA_SHOP_NAME']
        code = '03'
      when ENV['ZOBHA_SHOP_NAME']
        code = '06'
      when ENV['ELLIE_SHOP_NAME']
        code = 'EL'
    end
    code
  end

  def udf4
    case name
      when ENV['MARIKA_SHOP_NAME']
        code = 'Web00'
      when ENV['ZOBHA_SHOP_NAME']
        code = 'Web01'
      when ENV['ELLIE_SHOP_NAME']
        code = 'EL001'
    end
    code
  end

  def vendor_name
    case name
      when ENV['MARIKA_SHOP_NAME']
        name = 'Marika'
      when ENV['ZOBHA_SHOP_NAME']
        name = 'Zobha'
      when ENV['ELLIE_SHOP_NAME']
        name = 'Ellie'
    end
    name
  end
end
