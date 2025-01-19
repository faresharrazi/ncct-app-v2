class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:settings]
  before_action :set_devise_resource, only: [:settings]

  def settings
    @resource = current_user
    @resource_name = devise_mapping.name
    params[:preference] ||= 'main_account'
  end

  def home
    if user_signed_in?
      if current_user.main_accounts.any?
        redirect_to main_account_path(current_user.main_accounts.first)
      else
        redirect_to new_main_account_path, notice: 'Please create a main account.'
      end
    else
      redirect_to new_user_session_path
    end
  end

  private

  def set_devise_resource
    @resource = current_user
    @resource_name = devise_mapping.name
  end

  def devise_mapping
    Devise.mappings[:user]
  end
end