require 'rubygems'
require 'shopify_api'

class OrderWorker

  JOB_NAME = "OrderJob"
  FINANCIAL_STATUS = "paid"

  include Sidekiq::Worker
  sidekiq_options :retry => 5

  sidekiq_options backtrace: true

  sidekiq_retries_exhausted do |ctx, ex|
    Sidekiq.logger.warn "Failed #{ctx['class']} with #{ctx['args']}: #{ctx['error_message']}"
    ErrorService.notify(ex,ctx)
  end

  def perform(brand_name)
    brand = Brand.find_by_name(brand_name)
    last_runned_at = brand.last_runned_at(JOB_NAME)
    Shopify.new(brand_name)
    page=1
    loop do
      orders =  ShopifyAPI::Order.where(created_at_min: last_runned_at, financial_status: FINANCIAL_STATUS, limit: 250, page: page )

      orders.each do |order|
        new_order = Order.new_order_from_hash(order,brand_name)
        new_order.status = LogTrail.statuses[:received_from_shopify]
        new_order.trigger_type = LogTrail.trigger_types[:cron_job]
        unless brand.orders.find_by_name(new_order.name).present?
          new_order.save_order(LogTrail.trigger_types[:cron_job], LogTrail.statuses[:received_from_shopify])
        end
      end
      orders.count == 0 ? break : page+=1
    end

    brand.jobs.create!(name: JOB_NAME ,runned_at: Time.now)
  end


end
