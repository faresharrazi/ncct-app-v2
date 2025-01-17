class SharedMainAccountUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_shared_main_account_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner_or_partner!, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  def index
    @shared_users = @main_account.owners.where.not(id: current_user.id)
  end

  def show
    # Display details of a specific shared user
  end

  def new
    @shared_main_account_user = User.new
  end

  def create
    @shared_main_account_user = User.find(params[:user_id])
    if @shared_main_account_user
      # Remove the user from their current main account
      @shared_main_account_user.main_account&.owners&.delete(@shared_main_account_user)
      # Add the user to the new main account
      @main_account.owners << @shared_main_account_user
      @shared_main_account_user.update(main_account: @main_account)
      redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully added."
    else
      redirect_to main_account_shared_main_account_users_path(@main_account), alert: "Failed to add partner."
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
    reassign_to_new_main_account(@shared_main_account_user.user)
    redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully removed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
  end

  def set_shared_main_account_user
    @shared_main_account_user = @main_account.owners.find(params[:id])
  end

  def shared_main_account_user_params
    params.require(:shared_main_account_user).permit(:user_id)
  end

  def authorize_owner_or_partner!
    unless @main_account.owners.include?(current_user)
      redirect_to main_accounts_path, alert: "Only the owner or partners can perform this action."
    end
  end

  def reassign_to_new_main_account(user)
    new_main_account = MainAccount.create(owner: user, title: "New Main Account")
    user.update(main_account: new_main_account)
  end
end