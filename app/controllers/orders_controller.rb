class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update,:sync_failed_order_to_cims, :destroy]
  before_action :authenticate_user!, except:[:create]

  skip_before_action :verify_authenticity_token ,only: [:create]

  include ShopifyWebhook
  # GET /orders
  # GET /orders.json
  def index
    case filter_params.to_hash.count
      when 0
        @orders = Order.success_orders(session[:selected_brand]).
            order('created_at DESC').
            paginate(:page => params[:success_page], :per_page => 25)
        @fail_orders = Order.fail_orders(session[:selected_brand]).
            order('created_at DESC').
            paginate(:page => params[:failure_page], :per_page => 25)
      else
        @statuses = [filter_params[:status_fulfilled],
                     filter_params[:status_pushed_to_cims],
                     filter_params[:status_partially_fulfilled]].compact
        statuses = @statuses.map {|status| Order.statuses[status] }
        statuses = statuses.empty? ?
                       Order.statuses.values - [Order.statuses[:cims_push_failed]] :
                       statuses
        @to_date = filter_params[:to_date]
        @from_date = filter_params[:from_date]
        to_date  = @to_date.present? ?
                       Date.strptime(@to_date, '%m/%d/%Y') :
                       Time.now.to_date
        from_date  = @from_date.present? ?
                         Date.strptime(@from_date, '%m/%d/%Y') :
                         ('01/01/2005').to_date
        @orders = Order.success_orders(session[:selected_brand],statuses).
            where("(details ->> 'created_at') >= ? AND (details ->> 'created_at') <= ?",
                  from_date,to_date + 1.day).order('created_at DESC').
            paginate(:page => params[:success_page], :per_page => 25)
        @fail_orders = Order.fail_orders(session[:selected_brand]).
            where("(details ->> 'created_at') >= ? AND (details ->> 'created_at') <= ?",
                  from_date,to_date + 1.day).order('created_at DESC').
            paginate(:page => params[:failure_page], :per_page => 25)
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @enable_true = true
    @log_trails = @order.log_trails
    @enable_true = false if ["pushed_to_cims","partially_fulfilled","fulfilled"].
        include? (@log_trails.last.status)
    @log_trails = @log_trails.order('created_at DESC')
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  def sync_marika
    OrderWorker.perform_async(ENV['MARIKA_SHOP_NAME'])
    redirect_back(fallback_location: orders_path)
  end

  def sync_failed_orders_to_cims
    brand_names = Brand.brand_names(session[:selected_brand])
    CimsWorker.perform_async('sync_to_cims',brand_names)
    redirect_back(fallback_location: orders_path)
  end

  def sync_failed_order_to_cims
    items = @order.get_child_skus_from_collection
    @order.import_to_cims(items,@order.brand_id,LogTrail.trigger_types[:cims_manual_sync])
    redirect_to @order
  end

  # POST /orders (as webhooks from fambrand stores)
  def create
    request.body.rewind
    data = request.body.read
    verified = verify_webhook(data, request)
    if verified
      shop_name = get_shop_name(request)
      @order = Order.new_order_from_json(data, shop_name)
      if @order.present?
        @order.delay(:retry => false).save_order(LogTrail.trigger_types[:webhook], LogTrail.statuses[:received_from_shopify])
        head :ok
      end
    else
      head :error
    end
  end

  def trends_chart
    render json: [{name: "Orders", data:Order.where(status: Order.statuses[:cims_push_failed],brand_id: session[:selected_brand], created_at: (Time.now - 7.days)..Time.now).group_by_day(:created_at).count},{name: "Inventories", data: InventoryOnHand.where(created_at: (Time.now - 7.days)..Time.now,brand_id: session[:selected_brand]).group_by_day(:created_at).count},{name: "Fulfillment", data: Fulfillment.where(created_at: (Time.now - 7.days)..Time.now,brand_id: session[:selected_brand]).group_by_day(:created_at).count}]
  end

  def cims_trends_chart
    render json: [{name: "Orders pushed to CIMS (#{Brand.where(id: session[:selected_brand]).map(&:name).join(', ')})", data:Order.where(status: Order.statuses[:pushed_to_cims],brand_id: session[:selected_brand],created_at: (Time.now - 7.days)..Time.now).group_by_day_of_week(:created_at,format: "%a").count}]
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_order
    @order = Order.find_by_id(params[:id])
    unless @order.present? && session[:selected_brand].include?(@order.brand_id)
      redirect_to orders_path
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def order_params
    params.require(:order).permit(:name, :order_detail, :source, :brand_id, :tracking_id, :status, :price, :customer_name)
  end

  def filter_params
    filter_params = params.permit(:from_date,:to_date,:status_fulfilled, :status_pushed_to_cims,:status_partially_fulfilled)
    filter_params
  end
end
