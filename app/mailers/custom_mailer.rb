class CustomMailer < ApplicationMailer
  default template_path: 'mailer/custom_mailer'

  def custom_notification_utility(name,to,brand_name,milldleware,exception)
    @name = name
    @transaction_name = "#{milldleware}"
    @middleware = "#{milldleware} middleware"
    @error_message = exception.message rescue exception
    @error_type = "#{milldleware} Failed"
    @shop_name = brand_name
    @to = to
    subject = @shop_name +" "+ @middleware
    mail({subject: subject, to: to})
  end

  def worker_notification(name,to, ctx)
    @name = name
    @transaction_name = ctx['class'].gsub("Worker", "")
    @middleware = @transaction_name+" middleware"
    @error_message = ctx['error_message']
    @error_type = ctx['error_class']
    @queue = ctx['queue']
    @retry_count = ctx['retry_count']
    @shop_name = ctx['args'].first
    @to = to
    subject = @shop_name +" "+ @middleware
    mail({subject: subject, to: to})
  end

  def inventory_threshold_breach_notification(name,to,brand_names,middleware,csv)
    @name = name
    @transaction_name = "#{middleware}"
    @middleware = "#{middleware} middleware"
    @notification_type = INVENTORY_NOTIFICATION_TYPE
    @shop_name = brand_names
    @datetime = Time.now.in_time_zone("Pacific Time (US & Canada)")
    @to = to
    subject = @shop_name +" "+ @middleware
    attachments['inventory_update_report.csv'] = {mime_type: 'text/csv', content: csv}
    mail({subject: subject, to: to})
  end

end
