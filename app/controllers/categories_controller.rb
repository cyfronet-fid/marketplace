# frozen_string_literal: true

class CategoriesController < ApplicationController
  include Service::Searchable
  include Service::Sortable
  include Paginable

  before_action :category

  def show
    @services = paginate(category_services.order(ordering))
    @siblings = siblings
    @subcategories = category.children.order(:name)
    @provider_options = provider_options(category)
    @dedicated_for_options = dedicated_for_options(category)
    @rating_options = rating_options(category)
    @research_areas = ResearchArea.all
    @related_platform_options = related_platform_options(category)
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
      @category ||= Category.friendly.find(params[:id])
    end

    def siblings
      category.ancestry.nil? ? @root_categories : category.parent.children.order(:name)
    end
end
