# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

private

  def records
    filters.inject(search_scope) { |filtered, filter| filter.call(filtered) }
  end

  def search_scope
    query_present? ? scope.where(id: search_ids) : scope
  end

  def query_present?
    params[:q].present?
  end

  def search_ids
    scope.search(params[:q]).records.ids
  end

  def scope
    policy_scope(Service).with_attached_logo
  end

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
      Filter::Location,
      Filter::Provider,
      Filter::Platform,
      Filter::TargetGroup,
      Filter::Rating,
      Filter::ResearchArea,
      Filter::Tag
    ]
  end
end
