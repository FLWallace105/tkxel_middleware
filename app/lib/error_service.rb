class ErrorService
  class << self

    def notify(exception, ctx_hash)

      job_ctx = ctx_hash[:job]

      # add notify methods here
      notify_brand_users(job_ctx)
      notify_bugsnag(exception)
    end

    def notify_brand_users(job_ctx)
      brand = Brand.find_by_name(job_ctx['args'].first)
      brand.active_users.each do |user|
       CustomMailer.worker_notification(user.name, user.email, job_ctx).deliver!
      end
    end

    def notify_brand_users_utility(brand_id,exception,middleware)
      brand = Brand.find_by_id(brand_id)
      brand.active_users.each do |user|
        CustomMailer.custom_notification_utility(user.name,user.email,brand.name,middleware,exception).deliver!
      end
    end

    def notify_inventory_breach_utility(brand_ids,invenotry_change_csv_file)
      User.active_users.each do |user|
        brand_names = Brand.brand_names_string(brand_ids)
       CustomMailer.inventory_threshold_breach_notification(user.name,user.email,brand_names,INVENTORY_MIDDLEWARE_NAME,invenotry_change_csv_file).deliver! unless (user.brands.ids & brand_ids).empty?
      end
    end

    def notify_bugsnag(exception)
      Bugsnag.notify(exception)
    end

  end
end