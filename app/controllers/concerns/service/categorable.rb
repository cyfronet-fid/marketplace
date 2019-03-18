# frozen_string_literal: true

module Service::Categorable
  extend ActiveSupport::Concern

  included do
    before_action :init_categories_tree, only: :index
  end

  private
    def init_categories_tree
      @siblings = siblings
      @subcategories = category&.children&.order(:name)
    end

    def category_records(search_scope)
      if category
        search_scope.joins(:service_categories).
          where(service_categories: { category_id: category_and_descendant_ids })
      else
        search_scope
      end
    end

    def category
      @category ||= Category.friendly.find(params[:category_id]) if params[:category_id]
    end

    def category_and_descendant_ids
      [category] + category.descendant_ids
    end

    def siblings
      category&.ancestry.nil? ? @root_categories : category.parent.children.order(:name)
    end
end
