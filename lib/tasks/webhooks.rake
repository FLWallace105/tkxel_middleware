require 'rubygems'


namespace :webhooks do
  ReCharge.api_key = ENV['ellie_recharge_api_key']

  require 'recharge/tasks'

  desc "create shopify webhooks"
  task :create_shopify_webhooks => :environment do
    require 'shopify_api'
    include ShopifyWebhooks
    Brand.all.each do |brand|
      Shopify.new(brand.name)
      webhook = [{
                     topic: 'orders/paid',
                     address: "#{ENV['APP_URL']}/orders",
                     format: 'json'
                 },{
                     topic: 'products/create',
                     address: "#{ENV['APP_URL']}/inventory_on_hands/create_inventory_log",
                     format: 'json'
                 }]
      manager = WebhooksManager.new(webhook)
      manager.create_webhooks
    end
  end
end