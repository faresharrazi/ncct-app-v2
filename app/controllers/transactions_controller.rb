class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy]
  before_action :set_main_account, only: %i[new create edit]

  def index
    @transactions = Transaction.includes(:main_account, :sub_account, :category, :creator)
                               .where(main_account: current_user.main_accounts + current_user.shared_main_accounts)
                               .or(Transaction.where(sub_account: SubAccount.where(main_account: current_user.main_accounts)))
                               .order(created_at: :desc)
  end

  def new
    if @main_account.nil?
      redirect_to main_accounts_path, alert: "Please create a main account first."
    else
      @transaction = Transaction.new
    end
  end

  def create
    Rails.logger.debug "Transaction params: #{transaction_params.inspect}"
    @transaction = current_user.transactions.build(transaction_params)

    if @transaction.sub_account_id.blank?
      @transaction.main_account_id = @main_account.id
    end

    if @transaction.save
      redirect_to transactions_path, notice: "Transaction was successfully created."
    else
      Rails.logger.debug "Transaction creation failed: #{@transaction.errors.full_messages}"
      render :new, status: :unprocessable_entity
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

  def set_main_account
    @main_account = current_user.main_accounts.first
  end

  def transaction_params
    params.require(:transaction).permit(:title, :description, :amount, :transaction_kind, :sub_account_id, :category_id)
  end
end
