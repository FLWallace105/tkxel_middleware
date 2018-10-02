class ReserveInventoriesController < ApplicationController
  before_action :authenticate_user!, except:[:subscription_update]

  before_action :set_inventory, only: [:show, :edit, :update, :destroy]

  skip_before_action :verify_authenticity_token ,only: [:subscription_update]

  include RechargeWebhook

  # GET /ReserveInventories
  # GET /ReserveInventories.json
  def index
    @reserve_inventories = ReserveInventory.current_month.paginate(:page => params[:page], :per_page => 25)
  end

  def reserve_inventory
    if Product.get_main_default_product.present? && !(Job.is_current_month_inventory_reserved)
      ReserveInventoryWorker.perform_async
      redirect_to reserve_inventories_path, notice: 'Reserve Inventory process has been started at backend, please wait few seconds and refresh page.'
    else
      if Job.is_current_month_inventory_reserved
        redirect_to reserve_inventories_path, notice: 'Inventory for current month is already reserved'
      else
        redirect_to reserve_inventories_path, notice: 'Please add default products for current month before starting Reserve Inventory process.'
      end
    end
  end

  # reacharge webhook for subcription updated/canceled
  def subscription_update
    data = request.body.read
    @verified = verify_webhook(data, request)
    if @verified
      ReserveInventory.delay(:retry => false).update_reserve_inventory
      head :ok
    else
      head :error
    end
  end

  # GET /ReserveInventories/1
  # GET /ReserveInventories/1.json
  def show
  end

  # GET /ReserveInventories/new
  def new
    @reserve_inventory = ReserveInventory.new
  end

  # GET /ReserveInventories/1/edit
  def edit
  end

  # POST /ReserveInventories
  # POST /ReserveInventories.json
  def create
    @reserve_inventory = ReserveInventory.new(inventory_params)

    respond_to do |format|
      if @reserve_inventory.save
        format.html { redirect_to @reserve_inventory, notice: 'ReserveInventory was successfully created.' }
        format.json { render :show, status: :created, location: @reserve_inventory }
      else
        format.html { render :new }
        format.json { render json: @reserve_inventory.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ReserveInventories/1
  # PATCH/PUT /ReserveInventories/1.json
  def update
    respond_to do |format|
      if @reserve_inventory.update(inventory_params)
        format.html { redirect_to @reserve_inventory, notice: 'ReserveInventory was successfully updated.' }
        format.json { render :show, status: :ok, location: @reserve_inventory }
      else
        format.html { render :edit }
        format.json { render json: @reserve_inventory.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ReserveInventories/1
  # DELETE /ReserveInventories/1.json
  def destroy
    @reserve_inventory.destroy
    respond_to do |format|
      format.html { redirect_to reserve_inventories_path, notice: 'ReserveInventory was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_inventory
    @reserve_inventory = ReserveInventory.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_params
    params.require(:reserve_inventory).permit(:product_id, :brand_id, :style_id)
  end
end
