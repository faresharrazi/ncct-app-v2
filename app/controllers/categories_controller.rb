# app/controllers/categories_controller.rb
class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_main_account
  before_action :set_sub_account
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:new, :create, :edit, :update, :destroy]

  def index
    @categories = @sub_account.categories
  end

  def show
    unless @main_account.owner == current_user || @main_account.partners.include?(current_user)
      redirect_to main_accounts_path, alert: "You do not have access to this Category."
    end
  end

  def new
    @category = @sub_account.categories.build
  end

  def create
    @category = @sub_account.categories.build(category_params)
    if @category.save
      redirect_to [@main_account, @sub_account, @category], notice: "Category was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to [@main_account, @sub_account, @category], notice: "Category was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @category.destroy
    redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: "Category was successfully destroyed."
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id])
    unless @main_account.owner == current_user || @main_account.partners.include?(current_user)
      redirect_to main_accounts_path, alert: "You do not have access to this Main Account."
    end
  end

  def set_sub_account
    @sub_account = @main_account.sub_accounts.find(params[:sub_account_id])
  end

  def set_category
    @category = @sub_account.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:title, :description)
  end

  def authorize_owner!
    unless @main_account.owner == current_user
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), alert: "Only the owner can perform this action."
    end
  end
end
