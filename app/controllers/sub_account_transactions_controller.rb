class SubAccountTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account_and_sub_account, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :set_transaction, only: %i[show edit update destroy]

  def index
    @transactions = @sub_account.sub_account_transactions
  end

  def all
    @main_account = MainAccount.first # Adjust this to set the correct main account
    @transactions = SubAccountTransaction.joins(:sub_account).includes(:sub_account)
  end

  def show
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
  end

  def new
    @sub_account_transaction = SubAccountTransaction.new(sub_account_transaction_params)
    @sub_accounts = SubAccount.all
    @categories = Category.all
  end

  def new_without_subaccount
    @sub_account_transaction = SubAccountTransaction.new
    @sub_accounts = SubAccount.all
    @categories = Category.all # Assuming you have categories to select from
  end

  def create
    if params[:sub_account_transaction][:sub_account_id].present?
      @sub_account = SubAccount.find(params[:sub_account_transaction][:sub_account_id])
      @sub_account_transaction = @sub_account.sub_account_transactions.build(transaction_params)
    else
      @sub_account_transaction = SubAccountTransaction.new(transaction_params)
    end

    @sub_account_transaction.creator = current_user

    if @sub_account_transaction.save
      update_balances(@sub_account_transaction)
      redirect_to all_sub_account_transactions_path, notice: "Transaction was successfully created."
    else
      @sub_accounts = SubAccount.all
      @categories = Category.all
      if params[:sub_account_transaction][:sub_account_id].present?
        render :new, status: :unprocessable_entity
      else
        render :new_without_subaccount, status: :unprocessable_entity
      end
    end
  end

  def edit
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
    @sub_accounts = SubAccount.all
    @categories = Category.all
  end

  def update
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
    if @sub_account_transaction.update(transaction_params)
      update_balances(@sub_account_transaction)
      redirect_to main_account_sub_account_sub_account_transaction_path(@main_account, @sub_account, @sub_account_transaction),
                  notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sub_account_transaction.destroy
    update_balances(@sub_account_transaction, destroy: true)
    redirect_to all_sub_account_transactions_path, notice: "Transaction was successfully deleted."
  end

  private

  def set_main_account_and_sub_account
    @main_account = MainAccount.find(params[:main_account_id]) if params[:main_account_id]
    @sub_account = @main_account.sub_accounts.find(params[:sub_account_id]) if @main_account && params[:sub_account_id]
  end

  def set_transaction
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
  end

  def sub_account_transaction_params
    params.fetch(:sub_account_transaction, {}).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end

  def transaction_params
    params.require(:sub_account_transaction).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end

  def update_balances(transaction, destroy: false)
    delta = transaction.transaction_kind == "income" ? transaction.amount : -transaction.amount
    delta = -delta if destroy

    transaction.sub_account.update!(balance: transaction.sub_account.balance + delta)
    transaction.sub_account.main_account.update!(balance: transaction.sub_account.main_account.balance + delta)
  end
end