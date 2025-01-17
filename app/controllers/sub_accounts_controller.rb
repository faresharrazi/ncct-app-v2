class SubAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, except: [:balance]
  before_action :set_sub_account, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[new create edit update destroy]

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
      redirect_to main_accounts_path, alert: "You do not have access to this Account."
    end
  end

  def new
    @sub_account = @main_account.sub_accounts.build
    @sub_account_transaction = SubAccountTransaction.new
    @max_percentage = @main_account.available_percentage

  end

  def create
    @sub_account = @main_account.sub_accounts.build(sub_account_params)

    if @sub_account.save
      redirect_to main_account_sub_accounts_path(@main_account),
                  notice: "Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @max_percentage = @sub_account.percentage + @main_account.available_percentage
  end

  def update
    if @sub_account.update(sub_account_params)
      redirect_to main_account_sub_account_path(@main_account, @sub_account),
                  notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @sub_account.destroy
    redirect_to main_account_sub_accounts_path(@main_account),
                notice: "Account and all associated categories were successfully deleted."
  end

  private

  ### SETTERS ###

  def set_main_account
    @main_account = MainAccount.find_by(id: params[:main_account_id])
    unless @main_account && accessible_account?
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
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

  def authorize_owner!
    unless @main_account&.owner == current_user
      redirect_to main_account_sub_accounts_path(@main_account),
                  alert: "Only the owner can perform this action."
    end
  end

  def accessible_account?
    @main_account&.owner == current_user || @main_account&.partners&.include?(current_user)
  end
end