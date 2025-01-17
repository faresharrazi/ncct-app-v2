class PagesController < ApplicationController
  def home
    if user_signed_in?
      if current_user.main_account
        redirect_to main_account_path(current_user.main_account)
      else
        redirect_to new_user_session_path, alert: "You do not have a main account."
      end
    else
      redirect_to new_user_session_path
    end
  end
end