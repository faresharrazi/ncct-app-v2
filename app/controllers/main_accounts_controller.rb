# app/controllers/main_accounts_controller.rb
class MainAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @main_accounts = current_user.main_accounts + current_user.shared_main_accounts
  end

  def show
    redirect_to main_accounts_path, alert: "You do not have access to this Main Account." unless accessible_account?
  end

  def new
    @main_account = current_user.main_accounts.build
  end

  def create
    @main_account = current_user.main_accounts.build(main_account_params)
    if @main_account.save
      redirect_to @main_account, notice: "Main Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @main_account.update(main_account_params)
      redirect_to @main_account, notice: "Main Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @main_account.destroy
    redirect_to main_accounts_url, notice: "Main Account was successfully destroyed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:id])
  end

  def main_account_params
    params.require(:main_account).permit(:title, :available_percentage, :currency)
  end

  def authorize_owner!
    redirect_to main_accounts_path, alert: "Only the owner can perform this action." unless @main_account.owner == current_user
  end

  def accessible_account?
    @main_account.owner == current_user || @main_account.partners.include?(current_user)
  end
end
