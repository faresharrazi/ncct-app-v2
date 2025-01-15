class SubAccountTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account_and_sub_account, only: [:index, :new, :create]
  before_action :set_transaction, only: %i[show edit update destroy]

  def index
    @transactions = SubAccountTransaction.all # Ensure you load the data properly
    render 'sub_account_transactions/index' # Explicitly render the updated view path
  end

  def all
    @transactions = SubAccountTransaction.joins(:sub_account).includes(:sub_account)
  end

  def show; end

  def new
    @transaction = @sub_account.transactions.build
  end

  def new_without_subaccount
    @transaction = SubAccountTransaction.new
    @sub_accounts = SubAccount.all
  end

  def create
    @transaction = @sub_account.transactions.build(transaction_params)

    if @transaction.save
      update_balances(@transaction)
      redirect_to main_account_sub_account_transactions_path(@main_account),
                  notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    previous_amount = @transaction.amount
    previous_kind = @transaction.transaction_kind

    if @transaction.update(transaction_params)
      update_balances(@transaction, previous_amount, previous_kind)
      redirect_to main_account_sub_account_transactions_path(@main_account),
                  notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    revert_balances(@transaction)
    @transaction.destroy
    redirect_to main_account_sub_account_transactions_path(@main_account),
                notice: "Transaction was successfully deleted."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
  end

  def set_transaction
    @transaction = SubAccountTransaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:title, :amount, :transaction_kind)
  end

  def update_balances(transaction, previous_amount = nil, previous_kind = nil)
    delta = transaction.transaction_kind == "income" ? transaction.amount : -transaction.amount

    if previous_amount && previous_kind
      previous_delta = previous_kind == "income" ? previous_amount : -previous_amount
      delta -= previous_delta
    end

    transaction.sub_account.update!(balance: transaction.sub_account.balance + delta)
    @main_account.update!(balance: @main_account.balance + delta)
  end

  def revert_balances(transaction)
    delta = transaction.transaction_kind == "income" ? -transaction.amount : transaction.amount
    transaction.sub_account.update!(balance: transaction.sub_account.balance + delta)
    @main_account.update!(balance: @main_account.balance + delta)
  end
end
