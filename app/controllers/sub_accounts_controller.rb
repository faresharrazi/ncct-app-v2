class SubAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_sub_account, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:new, :create, :edit, :update, :destroy]

  def index
    @sub_accounts = @main_account.sub_accounts
  end

  def show
    unless @main_account.owner == current_user || @main_account.partners.include?(current_user)
      redirect_to main_accounts_path, alert: "You do not have access to this Account."
    end
  end

  def new
    @sub_account = @main_account.sub_accounts.build
  end

  def create
    @sub_account = @main_account.sub_accounts.build(sub_account_params)
    
    if @sub_account.save
      redirect_to main_account_sub_account_path(@main_account, @sub_account), notice: "SubAccount was successfully created."
    else
      render :new, alert: "Account could not be created."
    end
  end

  def edit
  end

  def update
    if @sub_account.update(sub_account_params)
      redirect_to main_account_sub_account_path(@main_account, @sub_account), notice: "Account was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @sub_account.destroy
    redirect_to main_account_sub_accounts_path(@main_account), notice: "Account was successfully destroyed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    unless @main_account.owner == current_user || @main_account.partners.include?(current_user)
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
  end

  def set_sub_account
    @sub_account = @main_account.sub_accounts.find(params[:id])
  end

  def sub_account_params
    params.require(:sub_account).permit(:title, :description, :percentage)
  end

  def authorize_owner!
    unless @main_account.owner == current_user
      redirect_to main_account_sub_accounts_path(@main_account), alert: "Only the owner can perform this action."
    end
  end
end
