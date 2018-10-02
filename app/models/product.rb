class Product < ApplicationRecord
  validates_presence_of :product_date,:product_id,:product_title
  validates_uniqueness_of :product_id

  belongs_to :brand
  before_validation :fetch_name_from_shopify
  scope :current_month,->{where("product_date >= ? AND product_date <= ?", Date.today.at_beginning_of_month ,Date.today.at_end_of_month)}

  def self.get_current_month_products_ids
    where("product_date >= ? AND product_date <= ?",Date.today.at_beginning_of_month,Date.today.at_end_of_month ).map{|product| product.product_id}
  end


  def self.get_default_product_ids
    where("product_date >= ? AND product_date <= ? AND is_default = ?",Date.today.at_beginning_of_month,Date.today.at_end_of_month ,true ).map{|product| product.product_id}
  end

  def self.get_main_default_product
    current_month_default = where("product_date >= ? AND product_date <= ? AND is_default = ?",Date.today.at_beginning_of_month,Date.today.at_end_of_month ,true )
    current_month_default.each do |default|
      if default.product_title.downcase.include? "5 items"
        return default.product_id
      end
    end
  end

  def fetch_name_from_shopify
    Shopify.new(ENV['ELLIE_SHOP_NAME'])
    self.product_title = ShopifyAPI::Product.find(:all, params:{ids: product_id}).first.title rescue nil
  end

end
