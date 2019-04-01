# frozen_string_literal: true

module Service::Filterable
  extend ActiveSupport::Concern

  included do
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
                      map { |f| f.new(params: params, category: @category) }
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
