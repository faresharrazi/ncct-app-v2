class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home about]

  def home
    if user_signed_in?
            redirect_to main_account_path(current_user.main_accounts.first)
    else
      redirect_to new_user_session_path
    end
  end

  def about
  end
end
