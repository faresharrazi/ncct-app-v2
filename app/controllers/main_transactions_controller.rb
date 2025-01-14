class MainTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_main_transaction, only: %i[show edit update destroy]

  def index
    @main_transactions = @main_account.main_transactions.order(created_at: :desc)
  end

  def show; end

  def new
    @main_transaction = @main_account.main_transactions.build
  end

  def create
    @main_transaction = @main_account.main_transactions.build(main_transaction_params)

    if @main_transaction.save
      adjust_main_account_balance_and_distribute(@main_transaction)
      redirect_to main_account_main_transactions_path(@main_account),
                  notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    old_amount = @main_transaction.amount
    old_kind = @main_transaction.transaction_kind

    if @main_transaction.update(main_transaction_params)
      adjust_main_account_balance_and_distribute(@main_transaction, old_amount, old_kind)
      redirect_to main_account_main_transactions_path(@main_account),
                  notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    adjust_main_account_balance_and_distribute(@main_transaction, revert: true)
    @main_transaction.destroy
    redirect_to main_account_main_transactions_path(@main_account),
                notice: "Transaction was successfully deleted."
  end

  private

  ### SETTERS ###

  def set_main_account
    @main_account = MainAccount.find_by(id: params[:main_account_id])
    unless @main_account && (@main_account.owner == current_user || @main_account.partners.include?(current_user))
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
  end

  def set_main_transaction
    @main_transaction = @main_account.main_transactions.find_by(id: params[:id])
    unless @main_transaction
      redirect_to main_account_main_transactions_path(@main_account), alert: "Transaction not found."
    end
  end

  ### STRONG PARAMETERS ###

  def main_transaction_params
    params.require(:main_transaction).permit(:title, :amount, :transaction_kind)
  end

  ### HELPERS ###

  def adjust_main_account_balance_and_distribute(main_transaction, old_amount = nil, old_kind = nil, revert: false)
    # Calculate the balance delta
    delta = main_transaction.transaction_kind == "income" ? main_transaction.amount : -main_transaction.amount

    # Handle updates and deletions
    if revert
      delta = main_transaction.transaction_kind == "income" ? -main_transaction.amount : main_transaction.amount
    elsif old_amount && old_kind
      old_delta = old_kind == "income" ? old_amount : -old_amount
      delta -= old_delta
    end

    # Update MainAccount balance
    @main_account.update!(balance: @main_account.balance + delta)

    # Distribute changes to sub-accounts
    distribute_to_sub_accounts(delta)
  end

  def distribute_to_sub_accounts(delta)
    return unless @main_account.sub_accounts.any?

    @main_account.sub_accounts.each do |sub_account|
      sub_delta = (sub_account.percentage / 100.0) * delta
      sub_account.update!(balance: sub_account.balance + sub_delta)
    end
  end
end
