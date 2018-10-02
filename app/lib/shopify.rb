require 'rubygems'
require 'shopify_api'

class Shopify

  def initialize(shop_name)
    shop_url = "https://#{ENV["#{shop_name}_api_key"]}:#{ENV["#{shop_name}_password"]}@#{shop_name}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
  end


end