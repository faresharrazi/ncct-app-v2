class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_sub_account
  before_action :set_category, only: %i[show edit update destroy]
  before_action :authorize_owner!, except: %i[index show]

  # List categories for a subaccount
  def index
    @categories = @sub_account.categories
  end

  # Show a single category
  def show
    unless can_access_main_account?
      redirect_to main_accounts_path, alert: "You do not have access to this Category."
    end
  end

  # Render the new category form
  def new
    @category = @sub_account.categories.build
  end

  # Create a new category
  def create
    @category = @sub_account.categories.build(category_params)
    if @category.save
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  notice: "Category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Render the edit category form
  def edit; end

  # Update a category
  def update
    if @category.update(category_params)
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  notice: "Category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Destroy a category
  def destroy
    if @category == @sub_account.default_category
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  alert: "Default category cannot be deleted."
    else
      @category.destroy
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  notice: "Category was successfully destroyed."
    end
  end

  private

  ### SETTERS ###

  # Set the main account
  def set_main_account
    @main_account = MainAccount.find_by(id: params[:main_account_id])
    unless can_access_main_account?
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
  end

  # Set the subaccount
  def set_sub_account
    @sub_account = @main_account&.sub_accounts&.find_by(id: params[:sub_account_id])
    unless @sub_account
      redirect_to main_account_path(@main_account), alert: "SubAccount not found."
    end
  end

  # Set the category
  def set_category
    @category = @sub_account&.categories&.find_by(id: params[:id])
    unless @category
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  alert: "Category not found."
    end
  end

  ### PARAMS ###

  # Permit category params
  def category_params
    params.require(:category).permit(:title, :description)
  end

  ### AUTHORIZATION ###

  # Check if the current user can access the main account
  def can_access_main_account?
    @main_account&.owner == current_user || @main_account&.partners&.include?(current_user)
  end

  # Restrict actions to the owner of the main account
  def authorize_owner!
    unless @main_account&.owner == current_user
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account),
                  alert: "Only the owner can perform this action."
    end
  end
end
