# frozen_string_literal: true

module Service::Categorable
  extend ActiveSupport::Concern

  included do
    before_action :init_categories_tree, only: :index
  end

  def category_counters(scope, filters)
    services = search_for_categories(scope, filters)
    counters = services.aggregations["categories"]["categories"]["buckets"].
        inject({}) { |h, e| h[e["key"]] = e["doc_count"]; h }
    counters.tap { |c| c[nil] = services.aggregations["categories"]["doc_count"] }
  end

  private
    def init_categories_tree
      @siblings = siblings
      @subcategories = subcategories
      @siblings_with_counters = siblings_with_counters
      @subcategories_with_counters = subcategories_with_counters
      @services_total ||= counters[nil]
    end

    def category
      @category ||= Category.friendly.find(params[:category_id]) if params[:category_id]
    end

    def siblings
      category&.ancestry.nil? ? @root_categories : category.siblings.order(:name)
    end

    def subcategories
      category&.children&.order(:name)
    end

    def siblings_with_counters
      siblings.inject({}) { |h, cat| h[cat.id] = { category: cat, counter: count_services(cat) }; h }
    end

    def subcategories_with_counters
      subcategories&.inject({}) { |h, cat| h[cat.id] = { category: cat, counter: count_services(cat) }; h }
    end

    def count_services(category)
      (counters[category.id] || 0) + category.descendants.reduce(0) { |p, c| p + (counters[c.id] || 0) }
    end

    def counters
      @counters ||= category_counters(scope, all_filters)
    end
end
