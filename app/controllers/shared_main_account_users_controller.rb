class SharedMainAccountUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, except: [:reject_invitation, :accept_invitation]
  before_action :set_shared_main_account_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner_or_partner!, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  def index
    @main_account = current_user.main_account
    @owners = @main_account.owners || []
    @invitations = SharedMainAccountUser.where(user: current_user, status: 'pending') || []
    @sent_invitations = @main_account.shared_main_account_users.where(status: 'pending') || []
  end

  def search
    @main_account = current_user.main_account
    @owners = @main_account.owners || []
    @invitations = SharedMainAccountUser.where(user: current_user, status: 'pending') || []
    @sent_invitations = @main_account.shared_main_account_users.where(status: 'pending') || []
    query = params[:query]
    if query.present?
      @search_results = User.where.not(id: @main_account.owners.pluck(:id))
                            .where("first_name LIKE ? OR last_name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
    else
      @search_results = []
    end
    render :index
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
      # Add the user to the new main account with pending status
      @main_account.shared_main_account_users.create(user: @shared_main_account_user, status: 'pending')
      redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner invitation was successfully sent."
    else
      redirect_to main_account_shared_main_account_users_path(@main_account), alert: "Failed to send partner invitation."
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
    redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Invitation was successfully canceled."
  end

  def accept_invitation
    Rails.logger.debug "Accept action called for SharedMainAccountUser with ID: #{params[:id]}"
    invitation = SharedMainAccountUser.find(params[:id])
    Rails.logger.debug "Invitation: #{invitation.inspect}"
    if invitation.user == current_user && invitation.status == 'pending'
      # Destroy the current user's main account if it exists
      current_user.main_account&.destroy
      # Update the invitation status to 'accepted'
      invitation.update(status: 'accepted')
      # Assign the main account from the invitation to the current user
      current_user.update(main_account: invitation.main_account)
      # Add the current user to the owners of the main account
      invitation.main_account.owners << current_user
      # Reload the current user to ensure the main account is correctly associated
      current_user.reload
      Rails.logger.debug "Current User Main Account: #{current_user.main_account.inspect}"
      # Redirect to the main account's shared main account users path
      redirect_to main_account_shared_main_account_users_path(current_user.main_account), notice: "Invitation accepted. You are now a partner."
    else
      redirect_to main_account_shared_main_account_users_path(current_user.main_account), alert: "Failed to accept invitation."
    end
  end

  def reject_invitation
    invitation = SharedMainAccountUser.find(params[:id])
    if invitation.user == current_user && invitation.status == 'pending'
      invitation.destroy
      redirect_to main_account_shared_main_account_users_path(current_user.main_account), notice: "Invitation rejected."
    else
      redirect_to main_account_shared_main_account_users_path(current_user.main_account), alert: "Failed to reject invitation."
    end
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
  end

  def set_shared_main_account_user
    @shared_main_account_user = @main_account.shared_main_account_users.find(params[:id])
  end

  def shared_main_account_user_params
    params.require(:shared_main_account_user).permit(:user_id)
  end

  def authorize_owner_or_partner!
    unless @main_account.owners.include?(current_user) || @main_account.shared_main_account_users.exists?(user: current_user, status: 'accepted')
      redirect_to main_accounts_path, alert: "Only the owner or partners can perform this action."
    end
  end
end