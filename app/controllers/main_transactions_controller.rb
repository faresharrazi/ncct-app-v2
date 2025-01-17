class MainTransactionsController < ApplicationController
  before_action :set_main_account
  before_action :set_main_transaction, only: %i[show edit update destroy repeat_without_edit]

  def new
    @main_transaction = @main_account.main_transactions.new(main_transaction_params)  
  end

  def create
    @main_transaction = @main_account.main_transactions.new(main_transaction_params)
    @main_transaction.creator = current_user

    if @main_transaction.save
      redirect_to main_account_path(@main_account), notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def repeat_without_edit
    @new_transaction = @main_account.main_transactions.build(
      title: @main_transaction.title,
      amount: @main_transaction.amount,
      transaction_kind: @main_transaction.transaction_kind,
      description: @main_transaction.description,
      creator: current_user
    )

    if @new_transaction.save
      redirect_to main_account_path(@main_account), notice: 'Transaction was successfully duplicated.'
    else
      redirect_to main_account_path(@main_account), alert: 'Failed to duplicate the transaction.'
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
    redirect_to main_account_path(current_user.main_account),
                notice: "Transaction was successfully destroyed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
  end

  def set_main_transaction
    @main_transaction = @main_account.main_transactions.find(params[:id])
  end

  def main_transaction_params
    params.fetch(:main_transaction, {}).permit(:title, :amount, :transaction_kind, :description, :date)  
  end
end