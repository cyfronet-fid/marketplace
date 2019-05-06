# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  included do
    include Paginable
    include Service::Sortable
  end

  def search(search_scope)
    Service.search *(list_params(search_scope))
  end

  def search_for_filters(search_scope)
    Service.search *(params_for_filters(search_scope))
  end

  def search_for_categories(search_scope)
    Service.search *(params_for_categories(search_scope))
  end

  private

    def query_present?
      params[:q].present?
    end

    def query
      query_present? ? params[:q] : "*"
    end

    def params_for_categories(search_scope)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          where: { id: search_scope.ids },
          match: :word_middle,
          aggs: [:categories]
      ]
    end

    def params_for_filters(search_scope)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          where: category_constr({ id: search_scope.ids }),
          match: :word_middle,
          aggs: [:research_areas, :providers, :platforms, :target_groups]
      ]
    end

    def list_params(search_scope)
      [
          query,
          fields: [ "title^7", "tagline^3", "description"],
          operator: "or",
          where: category_constr({ id: search_scope.ids }),
          page: params[:page],
          per_page: per_page,
          order: params[:sort].blank? ? nil : ordering,
          match: :word_middle,
          highlight: { fields: [:title], tag: "<b>" },
          scope_results: ->(r) { r.includes(:research_areas, :providers, :target_groups).with_attached_logo }
      ]
    end

    def category_constr(hash)
      hash[:categories] = category.id unless category.nil?
      hash
    end

    def highlights(from_search)
      (from_search.try(:with_highlights) || []).map { |s, h| [s.id, h] }.to_h
    end

    def filter_constr(hash)
      constr = {
          #status: status,
          #rating: rating,
          #research_areas: research_areas.map(&:id),
          #platforms: platforms.map(&:id),
          target_groups: ::TargetGroup.first.id
      }
      hash.merge!(constr)
    end
end
