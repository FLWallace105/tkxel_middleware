require 'rubygems'
require 'shopify_api'

class SubscriptionUpdateWorker

  JOB_NAME = "SubscriptionUpdateJob"

  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    brand = Brand.find_by_name(ENV['ELLIE_SHOP_NAME'])

    ReserveInventory.update_reserve_inventory

    brand.jobs.create!(name: JOB_NAME ,runned_at: Time.now)
  end


end
