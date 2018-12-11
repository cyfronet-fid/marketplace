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
    @provider_options = options_providers(category)
    @target_groups_options = options_target_groups(category)
    @rating_options = options_rating(category)
    @research_areas = options_research_area
    @tag_options = options_tag
    @active_filters = active_filters
    @related_platform_options = options_related_platforms(category)
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
