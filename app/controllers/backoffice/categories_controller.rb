# frozen_string_literal: true

class Backoffice::CategoriesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: [:show, :edit, :update, :destroy]

  def index
    authorize(Category)
    @categories = policy_scope(Category)
  end

  def show
  end

  def new
    @category = Category.new
    authorize(@category)
  end

  def create
    @category = Category.new(permitted_attributes(Category))
    authorize(@category)

    if @category.save
      redirect_to backoffice_category_path(@category),
                  notice: "New category created sucessfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @category.update(permitted_attributes(@category))
      redirect_to backoffice_category_path(@category),
                  notice: "Category updated correctly"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    @category.destroy!
    redirect_to backoffice_categories_path,
                notice: "Category destroyed"
  end

  private
    def find_and_authorize
      @category = Category.friendly.find(params[:id])
      authorize(@category)
    end
end
