class DashboardController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token ,only: [:brand_session_setting]
  # GET /dashboard
  def dashboard
    @user = current_user
    brands_options_for_select(@user) unless session[:selected_brand].present?
    @fail_inventory_count = InventoryOnHand.fail_inventory(session[:selected_brand]).count
    @fail_fulfillment_count = Fulfillment.fail_fulfillment(session[:selected_brand]).count
    @last_sync = Job.order_last_sync(session[:selected_brand])
    @last_since = (Time.now - 7.days).strftime('%^b %d,%Y %H:%m')
    @fail_orders_count = Order.failed_orders.count
  end

  def brand_session_setting
    session[:selected_brand] = JSON.parse(params[:sel1])
    if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      redirect_to(request.env["HTTP_REFERER"])
    else
      redirect_to root_url
    end
  end

end
