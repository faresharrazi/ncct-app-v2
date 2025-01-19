class ApplicationController < ActionController::Base

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_selected_main_account

  # Devise Redirects
  def after_sign_in_path_for(resource)
    resource.main_accounts.any? ? main_account_path(resource.main_accounts.first) : new_main_account_path
  end
  
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  private

def set_selected_main_account
  return unless current_user

  if session[:selected_main_account_id].present?
    @selected_main_account = current_user.main_accounts.find_by(id: session[:selected_main_account_id])
  end

  if @selected_main_account.nil?
    @selected_main_account = current_user.main_accounts.first
    session[:selected_main_account_id] = @selected_main_account&.id
  end
end

  def create_default_main_account
    default_main_account = MainAccount.create!(
      title: "New Main Account",
      available_percentage: 100.0,
      balance: 0.0
    )
    default_main_account.owners << current_user
    @selected_main_account = default_main_account
    session[:selected_main_account_id] = @selected_main_account.id
  end

  # Permit additional parameters for Devise actions
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end
end
