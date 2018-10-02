require 'rubygems'
require 'shopify_api'

class WebhookWorker
  include Sidekiq::Worker

  def perform
    Shopify.new("yourshop")
    # create_order_webhook
    create_subscription_webhook
  end

  def create_order_webhook
    webhook = {
        topic: 'product/update',
        address: "https://034dbd57.ngrok.io",
        format: 'json'
    }
    ShopifyAPI::Webhook.create(webhook)
  end

  def create_subscription_webhook

    cancelled = {
        topic: 'subscription/cancelled',
        address: "https://71c427ff.ngrok.io/reserve_inventories/subscription_update",
        format: 'json'
    }

    update = {
        topic: 'subscription/updated',
        address: "http://2a928e62.ngrok.io/reserve_inventories/subscription_update",
        format: 'json'
    }

    ReCharge.api_key = ENV['ellie_recharge_api_key']
    ReCharge::Webhook.create(update)
  end

end
