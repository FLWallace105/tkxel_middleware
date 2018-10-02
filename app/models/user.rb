class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :user_brands , dependent: :destroy
  has_many :brands, through: :user_brands
  accepts_nested_attributes_for :user_brands, allow_destroy: true
  devise :invitable, :database_authenticatable, 
         :recoverable, :rememberable, :trackable,
         :validatable, :confirmable
  scope :active_users, -> {where(deleted_at: nil).where.not(confirmed_at: nil)}
  # ensure he has access of that brand
  def has_brand?(brand_id)
    user_brands.any? { |b| b.brand_id == brand_id }
  end

  def brands_name
    brands_name = ''
    brands.each {|b| brands_name << b.name << ','}
    brands_name.chomp(',')
  end

  # instead of deleting, indicate the user requested a delete & timestamp it
  def soft_delete
    update_attribute(:deleted_at, Time.current)
  end

  # ensure user account is active
  def active_for_authentication?
    super && !deleted_at
  end

  # provide a custom message for a deleted account
  def inactive_message
    !deleted_at ? super : :deleted_account
  end



end
