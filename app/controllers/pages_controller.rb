class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  def home
    if user_signed_in?
      redirect_to main_account_path(current_user.main_account)
    else
      redirect_to new_user_session_path
    end
  end
end