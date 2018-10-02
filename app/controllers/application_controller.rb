class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  protected

  def authenticate_admin
    redirect_to root_url unless current_user.is_admin
  end


end
