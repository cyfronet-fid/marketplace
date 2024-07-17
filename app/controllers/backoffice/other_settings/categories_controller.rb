# frozen_string_literal: true

class Backoffice::OtherSettings::CategoriesController < Backoffice::ApplicationController
  before_action :find_and_authorize, only: %i[show edit update destroy]

  def index
    authorize(Category)
    @categories = policy_scope(Category).with_attached_logo
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
      redirect_to backoffice_other_settings_category_path(@category), notice: "New category created successfully"
    else
      render :new, status: :bad_request
    end
  end

  def edit
  end

  def update
    if @category.update(permitted_attributes(@category))
      redirect_to backoffice_other_settings_category_path(@category), notice: "Category updated successfully"
    else
      render :edit, status: :bad_request
    end
  end

  def destroy
    if @category.descendant_ids.present?
      redirect_back fallback_location: backoffice_other_settings_category_path(@category),
                    alert:
                      "This category has successors connected to it,
                            therefore is not possible to remove it. If you want to remove it,
                            edit them so they are not associated with this category anymore"
    elsif @category.services.present?
      redirect_back fallback_location: backoffice_other_settings_category_path(@category),
                    alert: "This category has services connected to it, remove associations to delete it."
    else
      @category.destroy!
      redirect_to backoffice_other_settings_categories_path, notice: "Category removed successfully"
    end
  end

  private

  def find_and_authorize
    @category = Category.with_attached_logo.friendly.find(params[:id])
    authorize(@category)
  end
end
