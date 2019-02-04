# frozen_string_literal: true

class CategoriesController < ApplicationController
  def show
    redirect_to category_services_path(category_id: params[:id])
  end
end
