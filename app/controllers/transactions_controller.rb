class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[show edit update destroy]
  before_action :set_main_account, only: %i[new create]
  before_action :set_categories, only: %i[new edit]

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
  @transaction = current_user.transactions.build(transaction_params)

  # Assign MainAccount if no SubAccount is selected
  @transaction.main_account_id ||= @main_account.id if @transaction.sub_account_id.blank?

  # Assign category for MainAccount transactions if none is provided
  if @transaction.main_account_id.present? && @transaction.category_id.nil?
    @transaction.category = Category.find_or_create_by!(
      title: @transaction.transaction_kind.capitalize,
      sub_account_id: nil
    )
  end

  if @transaction.save
    redirect_to transactions_path, notice: "Transaction was successfully created."
  else
    render :new, status: :unprocessable_entity
  end
end

  def edit; end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path, notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
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

  def set_categories
    @categories =
      if @transaction&.sub_account
        @transaction.sub_account.categories
      elsif @main_account&.sub_accounts&.first
        @main_account.sub_accounts.first.categories
      else
        []
      end
  end

  def assign_main_account_category(kind)
    # Assign the appropriate category for MainAccount based on the transaction kind
    main_account_default_categories = {
      'income' => Category.find_or_create_by!(title: 'Income', sub_account: nil, main_account: @transaction.main_account),
      'expense' => Category.find_or_create_by!(title: 'Expense', sub_account: nil, main_account: @transaction.main_account)
    }
    main_account_default_categories[kind].id
  end

  def transaction_params
    params.require(:transaction).permit(:title, :description, :amount, :transaction_kind, :sub_account_id, :category_id)
  end
end
