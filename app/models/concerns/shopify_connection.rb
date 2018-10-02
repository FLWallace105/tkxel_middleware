module ShopifyConnection
  extend ActiveSupport::Concern

  class_methods do
    def wait_for_shopify_credits
      if ShopifyAPI::credit_left < 4
        puts "sleeping for 10 seconds to obtain credits..."
        sleep(10)
      else
        puts "credit limit left #{ShopifyAPI::credit_left}"
      end
    end
  end
end