class ApplicationController < ActionController::Base
  # Devise Authentication
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Devise Redirects
  def after_sign_in_path_for(resource)
    resource.main_account ? main_account_path(resource.main_account) : main_account_path
  end
  
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

  # Permit additional parameters for Devise actions
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end
end
