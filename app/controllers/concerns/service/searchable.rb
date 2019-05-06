# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
  end

  def search(search_scope)
    query_present? ? (Service.search *(complex_params(search_scope))) : paginate(order(search_scope.distinct))
  end

  def search_simple(search_scope)
    query_present? ? (Service.search *(simple_params(search_scope))) : search_scope.distinct
  end

  private

    def query_present?
      params[:q].present?
    end

    def simple_params(search_scope)
      [
          params[:q],
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          where: { id: search_scope.ids },
          match: :word_middle,
      ]
    end

    def complex_params(search_scope)
      [
          params[:q],
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          where: { id: search_scope.ids },
          page: params[:page],
          per_page: per_page,
          order: params[:sort].blank? ? nil : ordering,
          match: :word_middle,
          highlight: { fields: [:title], tag: "<b>" },
          scope_results: ->(r) { r.includes(:research_areas, :providers, :target_groups).with_attached_logo }
      ]
    end

    def highlights(from_search)
      (from_search.try(:with_highlights) || []).map { |s, h| [s.id, h] }.to_h
    end
end
