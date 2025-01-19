class SubAccountTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account_and_sub_account, only: [:index, :new, :create, :edit, :update, :repeat_without_edit, :show, :destroy]
  before_action :set_transaction, only: %i[show edit update destroy repeat_without_edit]

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
    @sub_account_transaction = SubAccountTransaction.new
    @sub_account_transaction.transaction_kind ||= 'expense'
    @sub_accounts = current_user.main_accounts.includes(:sub_accounts).map(&:sub_accounts).flatten
    @categories = Category.where(sub_account_id: @sub_accounts.pluck(:id))
  end

  def new_without_subaccount
    @sub_account_transaction = SubAccountTransaction.new(sub_account_transaction_params)
    @sub_account_transaction.transaction_kind ||= 'expense'
    @main_account = current_user.main_account
    @sub_accounts = @main_account.sub_accounts
    if params[:sub_account_transaction].present?
      @categories = Category.where(sub_account_id: params[:sub_account_transaction][:sub_account_id])
    else
      @categories = Category.none
    end
  end

  def repeat_without_edit
    @new_transaction = @sub_account.sub_account_transactions.build(
      title: @sub_account_transaction.title,
      amount: @sub_account_transaction.amount,
      transaction_kind: @sub_account_transaction.transaction_kind,
      description: @sub_account_transaction.description,
      category_id: @sub_account_transaction.category_id,
      creator: current_user
    )

    if @new_transaction.save
      redirect_back fallback_location: main_account_sub_account_sub_account_transactions_path(@main_account, @sub_account), notice: 'Transaction was successfully duplicated.'
    else
      redirect_back fallback_location: main_account_sub_account_sub_account_transactions_path(@main_account, @sub_account), alert: 'Failed to duplicate the transaction.'
    end
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
      redirect_to all_sub_account_transactions_path, notice: "Transaction was successfully created."
    else
      @sub_accounts = SubAccount.all
      @categories = Category.where(sub_account_id: params[:sub_account_transaction][:sub_account_id])
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
    @categories = Category.where(sub_account_id: @sub_account_transaction.sub_account_id)
  end

  def update
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
    if @sub_account_transaction.update(transaction_params)
      redirect_to main_account_sub_account_sub_account_transaction_path(@main_account, @sub_account, @sub_account_transaction),
                  notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sub_account_transaction.destroy
    redirect_back fallback_location: main_account_sub_account_sub_account_transactions_path(@main_account, @sub_account), notice: "Transaction was successfully deleted."
  end

  private

  def set_main_account_and_sub_account
    @main_account = current_user.main_account
    if @main_account
      @sub_account = @main_account.sub_accounts.find(params[:sub_account_id]) if params[:sub_account_id]
    end
  end

  def set_transaction
    @sub_account_transaction = @sub_account.sub_account_transactions.find(params[:id])
  end

  def sub_account_transaction_params
    params.fetch(:sub_account_transaction, {}).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end

  def transaction_params
    params.require(:sub_account_transaction).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end
end