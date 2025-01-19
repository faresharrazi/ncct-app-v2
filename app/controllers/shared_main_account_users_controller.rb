class SharedMainAccountUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account, except: [:reject_invitation, :accept_invitation]
  before_action :set_user_to_remove, only: [:remove]
  before_action :authorize_owner_or_partner!, only: [:index, :show, :new, :create, :edit, :update, :destroy, :remove]

  def index
    @owners = @main_account.owners || []
    @invitations = SharedMainAccountUser.where(user: current_user, status: 'pending') || []
    @sent_invitations = @main_account.shared_main_account_users.where(status: 'pending') || []
  end

  def search
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

  def create
    @shared_main_account_user = User.find(params[:user_id])
    if @shared_main_account_user
      @main_account.shared_main_account_users.create(user: @shared_main_account_user, status: 'pending')
      redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner invitation was successfully sent."
    else
      redirect_to main_account_shared_main_account_users_path(@main_account), alert: "Failed to send partner invitation."
    end
  end

  def destroy
    @shared_main_account_user = @main_account.shared_main_account_users.find(params[:id])
    @shared_main_account_user.destroy
    redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Invitation was successfully canceled."
  end

  def remove
    user_to_remove = @user_to_remove
    shared_main_account_user = @main_account.shared_main_account_users.find_by(user_id: user_to_remove.id)
    shared_main_account_user&.destroy
    @main_account.owners.delete(user_to_remove)

    redirect_to main_account_shared_main_account_users_path(@main_account), notice: "Partner was successfully removed."
  end

def accept_invitation
  invitation = SharedMainAccountUser.find(params[:id])
  if invitation.user == current_user && invitation.status == 'pending'
    invitation.update(status: 'accepted')
    current_user.main_accounts << invitation.main_account unless current_user.main_accounts.include?(invitation.main_account)
    invitation.main_account.owners << current_user unless invitation.main_account.owners.include?(current_user)
    session[:selected_main_account_id] = invitation.main_account.id
    current_user.reload
    redirect_to main_account_path(invitation.main_account), notice: "Invitation accepted. You are now a partner."
  else
    redirect_to main_account_shared_main_account_users_path(invitation.main_account), alert: "Failed to accept invitation."
  end
end

  def reject_invitation
    invitation = SharedMainAccountUser.find(params[:id])
    if invitation.user == current_user && invitation.status == 'pending'
      invitation.destroy
      redirect_to main_account_shared_main_account_users_path(invitation.main_account), notice: "Invitation rejected."
    else
      redirect_to main_account_shared_main_account_users_path(invitation.main_account), alert: "Failed to reject invitation."
    end
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
  end

  def set_user_to_remove
    @user_to_remove = User.find(params[:id])
  end

  def shared_main_account_user_params
    params.require(:shared_main_account_user).permit(:user_id)
  end

  def authorize_owner_or_partner!
    unless @main_account.owners.include?(current_user) || @main_account.shared_main_account_users.exists?(user: current_user, status: 'accepted')
      redirect_to root_path, alert: "You have been deleted from the Shared Account."
    end
  end
end