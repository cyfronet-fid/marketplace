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

  def search_and_filter(search_scope)
    search(search_scope, filters)
  end

  private

    def visible_filters
      filters.select(&:visible?)
    end

    def filters
      @all_filters ||= filter_classes.
        map { |f| f.new(params: params) }.
        tap { |all| all.each { |f| f.counters = filter_counters(scope, all, f) } }
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
end
