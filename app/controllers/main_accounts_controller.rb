class MainAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, only: %i[show edit update destroy leave switch]
  before_action :authorize_owner_or_partner!, only: %i[show edit update destroy leave]
  before_action :set_selected_main_account, only: %i[show index]

  def index
    @main_accounts = current_user.main_accounts
  end

  def show
    if @main_account.nil?
      redirect_to new_main_account_path, notice: "Please create a new main account."
    else
      @main_transactions = @main_account.main_transactions.order(created_at: :desc)
      @sub_accounts = @main_account.sub_accounts.order(:created_at)
    end
  end 

  def new
    @selected_main_account = current_user.main_accounts.find_by(id: session[:selected_main_account_id])    
    @main_account = MainAccount.new(title: '', balance: 0, available_percentage: 100)
  end

  def create
    @main_account = MainAccount.new(main_account_params)
    if @main_account.save
      @main_account.owners << current_user
      @selected_main_account = @main_account
      session[:selected_main_account_id] = @selected_main_account.id
      redirect_to @main_account, notice: "Main Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @main_account.update(main_account_params)
      @selected_main_account = @main_account
      session[:selected_main_account_id] = @selected_main_account.id
      redirect_to @main_account, notice: "Main Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @main_account.owners.count == 1
      @main_account.destroy
    else
      @main_account.owners.delete(current_user)
    end
    set_selected_main_account
    Rails.logger.debug "After destroy, selected main account: #{@selected_main_account.inspect}"
    if @selected_main_account
      redirect_to main_account_path(@selected_main_account), notice: "Main Account was successfully deleted."
    else
      redirect_to new_main_account_path, notice: "Main Account was successfully deleted. Please create a new main account."
    end
  end

  def leave
    @main_account.owners.delete(current_user)
    if @main_account.owners.empty?
      @main_account.destroy
    end
    set_selected_main_account
    redirect_to main_account_path(@selected_main_account), notice: 'You left the main account.'
  end

  def switch
    @selected_main_account = @main_account
    session[:selected_main_account_id] = @selected_main_account.id
    redirect_to main_account_path(@selected_main_account), notice: "Switched to #{@selected_main_account.title}."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:id])
  end

  def main_account_params
    params.require(:main_account).permit(:title, :available_percentage, :currency)
  end

  def authorize_owner_or_partner!
    unless @main_account.owners.include?(current_user)
      redirect_to root_path, alert: "You no longer have access to this Main Account."
    end
  end
end