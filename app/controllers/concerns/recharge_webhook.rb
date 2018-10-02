module RechargeWebhook
  extend ActiveSupport::Concern

  def verify_webhook(data, request)
    hmac_header = request.env['HTTP_X_RECHARGE_HMAC_SHA256']
    calculated_hmac = Digest::SHA256.new
    calculated_hmac.update ENV["ellie_recharge_api_secret"]
    calculated_hmac.update data
    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac.hexdigest, hmac_header)
  end

end