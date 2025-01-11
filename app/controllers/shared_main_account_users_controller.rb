# app/controllers/shared_main_account_users_controller.rb
class SharedMainAccountUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_shared_main_account_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  def index
    @shared_users = @main_account.shared_main_account_users.includes(:user)
  end

  def show
    # Display details of a specific shared user
  end

  def new
    @shared_main_account_user = @main_account.shared_main_account_users.build
  end

  def create
    @shared_main_account_user = @main_account.shared_main_account_users.build(shared_main_account_user_params)
    if @shared_main_account_user.save
      redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully added."
    else
      render :new
    end
  end

  def edit
    # Typically, you might not need an edit action for a join model like this
    # But it's included here for completeness
  end

  def update
    if @shared_main_account_user.update(shared_main_account_user_params)
      redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @shared_main_account_user.destroy
    redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully removed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    unless @main_account.owner == current_user
      redirect_to main_accounts_path, alert: "Only the owner can manage partners for this Main Account."
    end
  end

  def set_shared_main_account_user
    @shared_main_account_user = @main_account.shared_main_account_users.find(params[:id])
  end

  def shared_main_account_user_params
    params.require(:shared_main_account_user).permit(:user_id)
  end

  def authorize_owner!
    unless @main_account.owner == current_user
      redirect_to main_accounts_path, alert: "Only the owner can perform this action."
    end
  end
end
