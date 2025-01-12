# app/controllers/transactions_controller.rb
class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  def index
    @transactions = Transaction.includes(:main_account, :sub_account, :category, :creator)
                               .where(main_account: current_user.main_accounts + current_user.shared_main_accounts)
                               .or(Transaction.where(sub_account: SubAccount.where(main_account: current_user.main_accounts)))
                               .order(created_at: :desc)
  end

  def new
    @transaction = Transaction.new
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    if @transaction.save
      redirect_to transactions_path, notice: "Transaction was successfully created."
    else
      render :new
    end
  end

  def edit; end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path, notice: "Transaction was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:title, :description, :amount, :transaction_kind, :main_account_id, :sub_account_id, :category_id)
  end
end
