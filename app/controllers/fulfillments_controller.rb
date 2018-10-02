class FulfillmentsController < ApplicationController
  before_action :set_fulfillment, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  # GET /fulfillments
  # GET /fulfillments.json
  def index
    @fulfillments = Fulfillment.fail_fulfillment(session[:selected_brand]).paginate(:page => params[:page], :per_page => 25)
  end


  def sync
    brand_names = Brand.brand_names(session[:selected_brand])
    CimsWorker.new.perform('fetch_fulfilment_cron',brand_names)
    redirect_back(fallback_location: fulfillments_path)
  end


end
