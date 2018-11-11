# frozen_string_literal: true

class CategoriesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  before_action :category

  def show
    @services = paginate(category_services.order(ordering))
    @siblings = category.ancestry.nil? ? @root_categories : category.ancestry.children.order(:name)
    @subcategories = category.children.order(:name)
    @provider_options = provider_options
    @dedicated_for_options = dedicated_for_options
    @rating_options = rating_options
    @research_areas = ResearchArea.all
  end

  def set_search_submit_path
    @search_submit_path = category_path
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
