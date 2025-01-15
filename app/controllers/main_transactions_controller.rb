class MainTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_main_transaction, only: %i[show edit update destroy]

  def index
    @main_transactions = @main_account.main_transactions.order(created_at: :desc)
  end

  def show; end
  
  def new
    if params[:main_transaction]
      @main_transaction = @main_account.main_transactions.build(
        title: params[:main_transaction][:title],
        amount: params[:main_transaction][:amount],
        transaction_kind: params[:main_transaction][:transaction_kind]
      )
    else
      @main_transaction = @main_account.main_transactions.build
    end
  end

  def create
    @main_transaction = @main_account.main_transactions.build(main_transaction_params)

    if @main_transaction.save
      redirect_to main_account_path(@main_account), notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @main_transaction.update(main_transaction_params)
      redirect_to main_account_path(@main_account), notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @main_transaction.destroy
    redirect_to main_account_path(@main_account), notice: "Transaction was successfully deleted."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    redirect_to main_accounts_path, alert: "You do not have access to this account." unless @main_account.owner == current_user
  end

  def set_main_transaction
    @main_transaction = @main_account.main_transactions.find(params[:id])
  end

  def main_transaction_params
    params.require(:main_transaction).permit(:title, :amount, :transaction_kind)
  end
end
