# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  before_action :authorize_access!

  def index
    @transactions = @account.transactions
  end

  def show
    unless authorized_to_view?(@account)
      redirect_to main_accounts_path, alert: "You do not have access to this Transaction."
    end
  end

  def new
    @transaction = @account.transactions.build
  end

  def create
    @transaction = @account.transactions.build(transaction_params)
    @transaction.creator = current_user

    if @transaction.save
      redirect_to [@account, @transaction], notice: "Transaction was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to [@account, @transaction], notice: "Transaction was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @transaction.destroy
    redirect_to account_transactions_path(@account), notice: "Transaction was successfully destroyed."
  end

  private

  # Set @account to either MainAccount or SubAccount based on params
  def set_account
    if params[:main_account_id]
      @account = MainAccount.find(params[:main_account_id])
    elsif params[:sub_account_id]
      @account = SubAccount.find(params[:sub_account_id])
    else
      redirect_to main_accounts_path, alert: "No account specified."
    end

    unless authorized_to_view?(@account)
      redirect_to main_accounts_path, alert: "You do not have access to this account."
    end
  end

  # Set @transaction based on @account
  def set_transaction
    @transaction = @account.transactions.find(params[:id])
  end

  # Strong parameters
  def transaction_params
    params.require(:transaction).permit(:title, :description, :amount, :transaction_type, :category_id, :main_account_id)
  end

  # Authorization: Ensure user can access the account
  def authorize_access!
    # Access is already handled in set_account
  end

  # Helper method to check if the user is authorized to view the account
  def authorized_to_view?(account)
    account.owner == current_user || account.partners.include?(current_user)
  end
end
