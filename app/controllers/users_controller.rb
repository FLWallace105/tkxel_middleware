class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :authenticate_admin

  # GET /users
  # GET /users.json
  def index
    @users = User.order(:id).paginate(:page => params[:page], :per_page => 10)
    @all_brands = Brand.all
    @user = User.new
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @all_brands = Brand.all
  end

  # GET /users/1/edit
  def edit
    @all_brands = Brand.all
  end

  # POST /users
  def create
    if user ||= User.invite!(user_params.except(:user_brands_attributes))
      user.update(user_brands_attributes: user_brands_params) unless user_params[:user_brands_attributes].nil?
      redirect_to users_path , notice: "User has been created succesfully!"
    else
      redirect_to users_path , notice: "Something went wrong."
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    if @user.update(user_params.except(:user_brands_attributes))
      @user.user_brands.destroy_all
      @user.update(user_brands_attributes: user_brands_params) unless user_params[:user_brands_attributes].nil?
      session[:selected_brand] = current_user.brand_ids if @user == current_user
      redirect_to users_path , notice: "User has been updated succesfully!"
    else
      redirect_to users_path , notice: "Something went wrong."
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.soft_delete
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'user was successfully deactivated.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id]) rescue redirect_to(users_url, notice: 'No such record found.')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :name, :password, :confirm_password, :user_brands_attributes => [:id, :brand_id , :_destroy])
    end
    def user_brands_params
      user_brands_attributes = user_params[:user_brands_attributes].to_hash.values rescue nil
    end
end
