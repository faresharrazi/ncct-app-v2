class MainAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, only: %i[show edit update destroy]
  before_action :authorize_owner_or_partner!, only: %i[show edit update destroy]

  def index
    @main_accounts = current_user.main_account ? [current_user.main_account] : []
  end

  def show
    @main_transactions = @main_account.main_transactions.order(created_at: :desc)
    @sub_accounts = @main_account.sub_accounts.order(:created_at)
  end

  def new
    @main_account = MainAccount.new
  end

  def create
    @main_account = MainAccount.new(main_account_params)
    if @main_account.save
      current_user.update(main_account: @main_account)
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
    if @main_account.owners.count == 1
      @main_account.destroy
      redirect_to main_accounts_path, notice: "Main Account was successfully deleted."
    else
      @main_account.owners.delete(current_user)
      redirect_to main_accounts_path, notice: "You have been removed from the Main Account."
    end
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:id])
  end

  def main_account_params
    params.require(:main_account).permit(:title, :available_percentage)
  end

  def authorize_owner_or_partner!
    unless @main_account.owners.include?(current_user)
      redirect_to root_path, alert: "You do not have access to this Main Account."
    end
  end
end