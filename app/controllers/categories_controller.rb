# frozen_string_literal: true

class CategoriesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  before_action :category

  def show
    @services = paginate(category_services)
    @subcategories = category.children
  end

  private

    def category_services
      records.joins(:service_categories).
        where(service_categories: { category_id: category_and_descendant_ids })
    end

    def category_and_descendant_ids
      [category] + category.descendant_ids
    end

    def category
      @category ||= Category.find(params[:id])
    end
end
