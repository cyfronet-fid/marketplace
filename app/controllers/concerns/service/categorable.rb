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
      siblings.inject({}) { |h, cat| h[cat.id] = {category: cat, counter: count_services(cat)}; h}
    end

    def subcategories_with_counters
      subcategories&.inject({}) { |h, cat| h[cat.id] = {category: cat, counter: count_services(cat)}; h}
    end

    def count_services(category)
      (counters[category.id] || 0) + category.descendants.reduce(0) { |p, c| p + (counters[c.id] || 0) }
    end

    def counters
      @counters ||= category_counters(scope, filters)
    end

end
