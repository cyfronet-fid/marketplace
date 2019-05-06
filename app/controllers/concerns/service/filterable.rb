# frozen_string_literal: true

module Service::Filterable
  extend ActiveSupport::Concern

  included do
    include Service::Searchable
    before_action only: :index do
      @filters = visible_filters
      @active_filters = active_filters
    end
  end

  def filter(search_scope)
    filters.inject(search_scope) { |filtered, filter| filter.call(filtered) }
  end

  private

    def visible_filters
      filters.select(&:visible?)
    end

    def filters
      @all_filters ||= filter_classes.
                      map { |f| f.new(params: params, category: @category, filter_scope: filter_scope) }
    end

    def active_filters
      @active_filters ||= filters.flat_map { |f| f.active_filters }
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

    def filter_scope
      @filter_scope ||= search_for_filters(scope)
    end
end
