# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_sub_account
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, except: [:index, :show]

  # List categories for a subaccount
  def index
    @categories = @sub_account.categories
  end

  # Show a single category
  def show
    redirect_to main_accounts_path, alert: "You do not have access to this Category." unless can_access_main_account?
  end

  # Render the new category form
  def new
    @category = @sub_account.categories.build
  end

  # Create a new category
  def create
    @category = @sub_account.categories.build(category_params)
    if @category.save
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: "Category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Render the edit category form
  def edit; end

  # Update a category
  def update
    if @category.update(category_params)
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: "Category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Destroy a category
  def destroy
    if @category == @sub_account.default_category
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), alert: "Default category cannot be deleted."
    else
      @category.destroy
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: "Category was successfully destroyed."
    end
  end

  private

  # Set the main account
  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    redirect_to main_accounts_path, alert: "You do not have access to this Main Account." unless can_access_main_account?
  end

  # Set the subaccount
  def set_sub_account
    @sub_account = @main_account.sub_accounts.find(params[:sub_account_id])
  end

  # Set the category
  def set_category
    @category = @sub_account.categories.find(params[:id])
  end

  # Permit category params
  def category_params
    params.require(:category).permit(:title, :description)
  end

  # Check if the current user can access the main account
  def can_access_main_account?
    @main_account.owner == current_user || @main_account.partners.include?(current_user)
  end

  # Restrict actions to the owner of the main account
  def authorize_owner!
    redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), alert: "Only the owner can perform this action." unless @main_account.owner == current_user
  end
end
