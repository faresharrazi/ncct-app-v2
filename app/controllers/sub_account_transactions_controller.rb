class SubAccountTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sub_account_transaction, only: %i[show edit update destroy]
  before_action :set_main_account
  before_action :set_sub_account
  before_action :set_categories, only: %i[new edit]

  def index
    @transactions = @sub_account.transactions.includes(:category, :creator).order(created_at: :desc)
  end

  def new
    @transaction = @sub_account.transactions.build
  end

  def create
    @transaction = @sub_account.transactions.build(transaction_params.merge(creator: current_user))

    if @transaction.save
      # Reflect changes in the SubAccount and MainAccount balances
      adjust_balances(@transaction)
      redirect_to main_account_sub_account_transactions_path(@main_account, @sub_account),
                  notice: "Transaction was successfully created."
    else
      set_categories
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    old_amount = @transaction.amount
    old_kind = @transaction.transaction_kind

    if @transaction.update(transaction_params)
      adjust_balances(@transaction, old_amount, old_kind)
      redirect_to main_account_sub_account_transactions_path(@main_account, @sub_account),
                  notice: "Transaction was successfully updated."
    else
      set_categories
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    adjust_balances(@transaction, revert: true)
    @transaction.destroy
    redirect_to main_account_sub_account_transactions_path(@main_account, @sub_account),
                notice: "Transaction was successfully deleted."
  end

  private

  ### SETTERS ###

  def set_sub_account_transaction
    @transaction = SubAccountTransaction.find_by(id: params[:id])
    unless @transaction
      redirect_to main_account_sub_account_transactions_path(@main_account, @sub_account),
                  alert: "Transaction not found."
    end
  end

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    unless @main_account.owner == current_user || @main_account.partners.include?(current_user)
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
  end

  def set_sub_account
    @sub_account = @main_account.sub_accounts.find_by(id: params[:sub_account_id])
    unless @sub_account
      redirect_to main_account_path(@main_account), alert: "SubAccount not found."
    end
  end

  def set_categories
    @categories = @sub_account.categories
  end

  ### STRONG PARAMETERS ###

  def transaction_params
    params.require(:sub_account_transaction).permit(:title, :description, :amount, :transaction_kind, :category_id)
  end

  ### HELPERS ###

  def adjust_balances(transaction, old_amount = nil, old_kind = nil, revert: false)
    delta = transaction.transaction_kind == "income" ? transaction.amount : -transaction.amount

    # Handle balance adjustments on update or delete
    if revert
      delta = transaction.transaction_kind == "income" ? -transaction.amount : transaction.amount
    elsif old_amount && old_kind
      old_delta = old_kind == "income" ? old_amount : -old_amount
      delta -= old_delta
    end

    @sub_account.update!(balance: @sub_account.balance + delta)
    @main_account.update!(balance: @main_account.balance + delta)
  end
end
