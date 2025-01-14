class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home about]

  def home
    if user_signed_in?
      redirect_to main_accounts_path
    else
      redirect_to new_user_session_path
    end
  end

  def about
  end
end
