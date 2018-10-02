class InventoryOnHandsController < ApplicationController
  before_action :authenticate_user!, except:[:create_inventory_log]

  skip_before_action :verify_authenticity_token ,only: [:create_inventory_log]

  include ShopifyWebhook

  def index
    @inventories = InventoryOnHand.fail_inventory(session[:selected_brand]).paginate(:page => params[:page], :per_page => 25)
  end

  def sync
    brand_names = Brand.brand_names(session[:selected_brand])
    CimsWorker.new.perform('update_inventory_onhand',brand_names)
    redirect_back(fallback_location: inventory_on_hands_path)
  end

  def create_inventory_log
    request.body.rewind
    @product = request.body.read
    @verified = verify_webhook(@product, request)
    if @verified
      @shop_name = get_shop_name(request)
      InventoryLog.delay(:retry => false).save_variants_inventory(@product,@shop_name)
      head :ok
    else
      head :error
    end
  end

end
