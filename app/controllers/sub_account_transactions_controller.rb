class SubAccountTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account_and_sub_account, only: [:index, :new, :create, :edit, :update, :repeat_without_edit, :show, :destroy]
  before_action :set_transaction, only: %i[show edit update destroy repeat_without_edit]

  def index
    @transactions = @sub_account.sub_account_transactions
  end

  def all
    @main_account = current_user.main_accounts.find_by(id: session[:selected_main_account_id])
    if @main_account.nil?
      redirect_to main_accounts_path, alert: "Please select a main account."
      return
    end

    @transactions = SubAccountTransaction.joins(:sub_account).where(sub_accounts: { main_account_id: @main_account.id }).includes(:sub_account)
    @transactions = search_transactions(@transactions)
    @transactions = filter_transactions(@transactions)
    @transactions = sort_transactions(@transactions)
  end

  def show
    @sub_account_transaction = SubAccountTransaction.find(params[:id])
  end

  def new
    @sub_account_transaction = SubAccountTransaction.new
    @sub_account_transaction.transaction_kind ||= 'expense'
    @sub_accounts = current_user.main_accounts.includes(:sub_accounts).map(&:sub_accounts).flatten
    @categories = Category.where(sub_account_id: @sub_accounts.pluck(:id))
    session[:return_to] = request.referer
  end

  def new_without_subaccount
    session[:return_to] = request.referer
    @sub_account_transaction = SubAccountTransaction.new(sub_account_transaction_params)
    @sub_account_transaction.transaction_kind ||= 'expense'
    @main_account = @selected_main_account
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
     redirect_to session.delete(:return_to) || all_sub_account_transactions_path, notice: "Transaction was successfully created."
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
    @main_account = @selected_main_account
    if @main_account
      @sub_account = @main_account.sub_accounts.find(params[:sub_account_id]) if params[:sub_account_id]
    end
  end

  def set_transaction
    @sub_account_transaction = @sub_account.sub_account_transactions.find(params[:id])
  end

  def search_transactions(transactions)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      transactions = transactions.where("LOWER(sub_account_transactions.title) LIKE ?", search_term.downcase)
    end
    transactions
  end

  def filter_transactions(transactions)
    if params[:category_id].present?
      transactions = transactions.where(category_id: params[:category_id])
    end

    if params[:sub_account_id].present?
      transactions = transactions.where(sub_account_id: params[:sub_account_id])
    end

    if params[:creator_id].present?
      transactions = transactions.where(creator_id: params[:creator_id])
    end

    if params[:start_date].present? && params[:end_date].present?
      transactions = transactions.where(created_at: params[:start_date]..params[:end_date])
    elsif params[:month].present?
      begin
        start_date = Date.strptime(params[:month], "%Y-%m").beginning_of_month
        end_date = Date.strptime(params[:month], "%Y-%m").end_of_month
        transactions = transactions.where(created_at: start_date..end_date)
      rescue Date::Error
        # Handle invalid date format
        flash[:alert] = "Invalid date format"
      end
    end

    transactions
  end

  def sort_transactions(transactions)
    case params[:sort]
    when "amount_asc"
      transactions = transactions.order(amount: :asc)
    when "amount_desc"
      transactions = transactions.order(amount: :desc)
    when "date_asc"
      transactions = transactions.order(created_at: :asc)
    when "date_desc"
      transactions = transactions.order(created_at: :desc)
    when "title_asc"
      transactions = transactions.order(:title)
    when "title_desc"
      transactions = transactions.order(title: :desc)
    when "creator_asc"
      transactions = transactions.joins(:creator).order(Arel.sql("users.first_name || ' ' || users.last_name ASC"))
    when "creator_desc"
      transactions = transactions.joins(:creator).order(Arel.sql("users.first_name || ' ' || users.last_name DESC"))
    when "account_asc"
      transactions = transactions.joins(:sub_account).order(Arel.sql("sub_accounts.title ASC"))
    when "account_desc"
      transactions = transactions.joins(:sub_account).order(Arel.sql("sub_accounts.title DESC"))
    when "category_asc"
      transactions = transactions.joins(:category).order(Arel.sql("categories.title ASC"))
    when "category_desc"
      transactions = transactions.joins(:category).order(Arel.sql("categories.title DESC"))
    end
    transactions
  end

  def sub_account_transaction_params
    params.fetch(:sub_account_transaction, {}).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end

  def transaction_params
    params.require(:sub_account_transaction).permit(:title, :amount, :transaction_kind, :description, :date, :sub_account_id, :category_id)
  end
end