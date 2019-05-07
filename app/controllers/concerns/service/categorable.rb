# frozen_string_literal: true

module Service::Categorable
  extend ActiveSupport::Concern

  included do
    include Service::Searchable
    before_action :init_categories_tree, only: :index
  end

  private
    def init_categories_tree
      @siblings = siblings
      @subcategories = category&.children&.order(:name)
      @siblings_with_counters = siblings_with_counters
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

    def siblings_with_counters
      siblings.inject({}) { |h, cat| h[cat.id] = {category: cat, counter: counters[cat.id] || 0}; h}
    end

    def categories_scope
      @categories_scope ||= search_for_categories(scope, filters)
    end

    def counters
      @counters ||= categories_scope.aggregations["categories"]["categories"]["buckets"].
          inject({}){ |h, e| h[e["key"]]=e["doc_count"]; h}
      @services_total ||= categories_scope.aggregations["categories"]["doc_count"]
      @counters
    end

end
