# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
  end

  def search(search_scope, filters)
    Service.search *(params_for_search(search_scope, filters))
  end

  def search_for_filters(search_scope, filters, current_filter)
    Service.search *(params_for_filters(search_scope, filters, current_filter))
  end

  def search_for_categories(search_scope, filters)
    Service.search *(params_for_categories(search_scope, filters))
  end

  private

    def query_present?
      params[:q].present?
    end

    def query
      query_present? ? params[:q] : "*"
    end

    def params_for_categories(search_scope, filters)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          match: :word_middle,
          where: filter_constr(filters, id_constr(search_scope)),
          aggs: [:categories],
          load: false
      ]
    end

    def params_for_filters(search_scope, filters, current_filter)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          match: :word_middle,
          where: filter_constr(filters.reject {|f| f == current_filter}, id_constr(search_scope, category_constr())),
          aggs: filters.map(&:index).reject(&:blank?),
          load: false
      ]
    end

    def params_for_search(search_scope, filters)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          match: :word_middle,
          where: filter_constr(filters, id_constr(search_scope, category_constr())),
          page: params[:page],
          per_page: per_page,
          order: params[:sort].blank? ? nil : ordering,
          highlight: { fields: [:title], tag: "<b>" },
          scope_results: ->(r) { r.includes(:research_areas, :providers, :target_groups).with_attached_logo }
      ]
    end

    def id_constr(search_scope, constr = {})
      constr.merge!({ id: search_scope.ids })
    end

    def category_constr(constr = {})
      constr.tap { |c| c[:categories] = category.id unless category.nil? }
    end

    def filter_constr(filters, constr = {})
      filters.reduce(constr) { |h, f| h.merge(f.constraint) }
    end

    def highlights(from_search)
      (from_search.try(:with_highlights) || []).map { |s, h| [s.id, h] }.to_h
    end

end
