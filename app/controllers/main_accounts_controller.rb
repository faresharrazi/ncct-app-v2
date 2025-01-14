class MainAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]

  def index
    @main_accounts = current_user.main_accounts + current_user.shared_main_accounts
  end

  def show
    unless accessible_account?
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
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
    if @main_account.sub_accounts.exists? || @main_account.transactions.exists?
      redirect_to main_account_path(@main_account),
                  alert: "Cannot delete a Main Account with associated SubAccounts or Transactions."
    else
      @main_account.destroy
      redirect_to main_accounts_url, notice: "Main Account was successfully destroyed."
    end
  end

  private

  ### SETTERS ###

  def set_main_account
    @main_account = MainAccount.find_by(id: params[:id])
    unless @main_account
      redirect_to main_accounts_path, alert: "Main Account not found."
    end
  end

  ### STRONG PARAMETERS ###

  def main_account_params
    params.require(:main_account).permit(:title, :available_percentage, :currency)
  end

  ### AUTHORIZATION ###

  def authorize_owner!
    unless @main_account&.owner == current_user
      redirect_to main_accounts_path, alert: "Only the owner can perform this action."
    end
  end

  def accessible_account?
    @main_account&.owner == current_user || @main_account&.partners&.include?(current_user)
  end
end
