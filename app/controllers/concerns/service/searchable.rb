# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
    include Service::Categorable
    before_action only: :index do
      @filters = visible_filters
      @active_filters = active_filters
      session[:category] = @category&.id
    end
  end

  def search(scope, filters = all_filters)
    Service.search(query, common_params.
        merge(where: filter_constr(filters, scope_constr(scope, category_constr)),
             page: params[:page],
             per_page: per_page,
             order: ordering,
             highlight: { fields: [:title, :tagline], tag: "<mark>" },
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

    def visible_filters
      all_filters.select(&:visible?)
    end

    def all_filters
      @all_filters ||= filter_classes.
          map { |f| f.new(params: params) }.
          tap { |all| all.each { |f| f.counters = filter_counters(scope, all, f) } }
    end

    def active_filters
      @active_filters ||= all_filters.flat_map { |f| f.active_filters }
    end

    def filter_classes
      [
          Filter::ResearchArea,
          Filter::Provider,
          Filter::TargetGroup,
          Filter::Platform,
          Filter::Rating,
          Filter::Location,
          Filter::Tag
      ]
    end
end
