class CategoriesController < ApplicationController
  before_action :set_main_account, except: [:index]
  before_action :set_sub_account
  before_action :set_category, only: %i[show edit update destroy]

  def index
    @categories = @sub_account.categories

    respond_to do |format|
      format.html
      format.json { render json: @categories }
    end
  end

  def show; end

  def new
    @category = @sub_account.categories.build
  end

  def create
    @category = @sub_account.categories.build(category_params)
    if @category.save
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: 'Category was successfully created.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: 'Category was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @category.destroy
    redirect_to main_account_sub_account_categories_path(@main_account, @sub_account), notice: 'Category was successfully deleted.'
  end

  private

  def set_main_account
    @main_account = MainAccount.find(params[:main_account_id]) if params[:main_account_id]
  end

  def set_sub_account
    @sub_account = SubAccount.find(params[:sub_account_id])
  end

  def set_category
    @category = @sub_account.categories.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:title, :description)
  end
end