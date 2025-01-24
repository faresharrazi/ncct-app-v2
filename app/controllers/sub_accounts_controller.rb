class SubAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, except: [:balance]
  before_action :set_sub_account, only: %i[show edit update destroy update_total_spent_period]
  before_action :authorize_owner_or_partner!, only: %i[new create edit update destroy]

  def index
    @sub_accounts = @main_account.sub_accounts
  end

  def balance
    @sub_account = SubAccount.find_by(id: params[:id])
    if @sub_account
      render json: { balance: @sub_account.balance }
    else
      render json: { error: "SubAccount not found" }, status: :not_found
    end
  end

  def show
    unless accessible_account?
      redirect_to main_accounts_path, alert: "No access to this Account."
      return
    end

    # Get the user's choice from the session or default to 'month'
    @total_spent_period = session[:total_spent_period] || 'month'

    # Calculate the total spent based on the user's choice
    if @total_spent_period == 'all'
      @total_spent = @sub_account.sub_account_transactions.where(transaction_kind: 'expense').sum(:amount)
    else
      @total_spent = @sub_account.sub_account_transactions.where(transaction_kind: 'expense', created_at: Time.current.beginning_of_month..Time.current.end_of_month).sum(:amount)
    end
  end

  def update_total_spent_period
    # Save the user's choice in the session
    session[:total_spent_period] = params[:total_spent_period]
    redirect_to main_account_sub_account_path(@main_account, @sub_account)
  end

  def new
    @sub_account = @main_account.sub_accounts.build
    @sub_account_transaction = SubAccountTransaction.new
    @max_percentage = @main_account.available_percentage
  end

  def create
    @sub_account = @main_account.sub_accounts.build(sub_account_params)

    if @sub_account.save
      redirect_to main_account_sub_accounts_path(@main_account), notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @max_percentage = @sub_account.percentage + @main_account.available_percentage
  end

  def update
    if @sub_account.update(sub_account_params)
      redirect_to main_account_sub_account_path(@main_account, @sub_account), notice: "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sub_account.destroy
    redirect_to main_account_sub_accounts_path(@main_account), notice: "Account deleted."
  end

  private

  ### SETTERS ###

  def set_main_account
    @main_account = MainAccount.find_by(id: params[:main_account_id])
    unless @main_account && accessible_account?
      redirect_to main_accounts_path, alert: "No access to this Account."
    end
  end

  def set_sub_account
    @sub_account = @main_account&.sub_accounts&.find_by(id: params[:id])
    unless @sub_account
      redirect_to main_account_sub_accounts_path(@main_account), alert: "Account not found."
    end
  end

  ### STRONG PARAMETERS ###

  def sub_account_params
    params.require(:sub_account).permit(:title, :description, :percentage)
  end

  ### AUTHORIZATION ###

  def authorize_owner_or_partner!
    unless accessible_account?
      redirect_to main_accounts_path, alert: "No access to this Account."
    end
  end

  def accessible_account?
    @main_account&.owners&.include?(current_user)
  end
end