module ShopifyWebhook
  extend ActiveSupport::Concern

  def verify_webhook(data, request)
    hmac_header = request.env['HTTP_X_SHOPIFY_HMAC_SHA256']
    calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', ENV["#{get_shop_name(request)}_webhook_token"], data))
    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
  end

  def get_shop_name(request)
    request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN'].partition(".").first.to_s
  end

end