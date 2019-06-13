# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
    include Service::Categorable
  end

  def search(scope, filters)
    Service.search(query, common_params.
        merge(where: filter_constr(filters, scope_constr(scope, category_constr)),
             page: params[:page],
             per_page: per_page,
             order: ordering,
             highlight: { fields: [:title], tag: "<b>" },
             scope_results: ->(r) { r.includes(:research_areas, :providers, :target_groups).with_attached_logo }))
  end

  def search_for_filters(scope, filters, current_filter)
    filters = filters - [current_filter]
    Service.search(query, common_params.
        merge(where: filter_constr(filters, scope_constr(scope, category_constr)),
              aggs: [current_filter.index],
              load: false))
  end

  def search_for_categories(scope, filters)
    Service.search(query, common_params.
        merge(where: filter_constr(filters, scope_constr(scope)),
              aggs: [:categories],
              load: false))
  end

  def filter_counters(scope, filters, current_filter)
    {}.tap do |hash|
      unless current_filter.index.blank?
        services = search_for_filters(scope, filters, current_filter)
        services.aggregations[current_filter.index][current_filter.index]["buckets"].
            inject(hash) { |h, e| h[e["key"]] = e["doc_count"]; h }
      end
    end
  end

  def category_counters(scope, filters)
    services = search_for_categories(scope, filters)
    counters = services.aggregations["categories"]["categories"]["buckets"].
        inject({}) { |h, e| h[e["key"]] = e["doc_count"]; h }
    counters.tap { |c| c[nil] = services.aggregations["categories"]["doc_count"] }
  end

  private

    def query_present?
      params[:q].present?
    end

    def query
      query_present? ? params[:q] : "*"
    end

    def common_params
      {
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          match: :word_middle
      }
    end

    def scope_constr(scope, constr = {})
      constr.tap { |c| c[:id] = scope.ids.uniq }
    end

    def category_constr(constr = {})
      constr.tap { |c| c[:categories] = category.descendant_ids + [category.id] unless category.nil? }
    end

    def filter_constr(filters, constr = {})
      filters.reduce(constr) { |c, f| c.merge(f.constraint) }
    end

    def highlights(from_search)
      (from_search.try(:with_highlights) || []).map { |s, h| [s.id, h] }.to_h
    end
end
