# frozen_string_literal: true

class Filter
  attr_accessor :counters
  attr_reader :title, :field_name, :type, :index

  def initialize(field_name:, type:, title:, index:, model_type: nil, params: {})
    @params = params
    @field_name = field_name
    @title = title
    @type = type
    @index = index
    @model_type = model_type
  end

  def options
    @options ||= fetch_options
  end

  def active_filters
    values.map { |v| [title, name(v), remove_filter_params(v)] }.reject { |f| f[0].blank? }
  end

  def present?
    values.present?
  end

  def blank?
    !present?
  end

  def visible?
    true
  end

  def values
    (value.is_a?(Array) ? value : [value]).reject(&:blank?)
  end

  def constraint
    active? ? where_constraint : {}
  end

  protected

  def fetch_options
    raise "Need to be implemented in descendent class!!!"
  end

  def where_constraint
    raise "Need to be implemented in descendent class!!!"
  end

  def value
    @value ||= @params[field_name]
  end

  def active?
    value.present?
  end

  private

  def name(val)
    options.find { |option| val.downcase == option[:id].to_s.downcase }&.[](:name)
  end

  def children(val)
    options.find { |option| val == option[:id].to_s }&.[](:children)
  end

  def parent(val)
    options&.flat_map { |o| o&.[](:children) }&.find { |option| val == option&.[](:id).to_s }&.[](:parent_id)
  end

  def remove_filter_params(val)
    params = @params.permit!.to_h
    children_ids = children(val)&.map { |child| child[:id].to_s }
    parent_id = parent(val)
    if value.is_a?(Array)
      params[field_name].delete(val.to_s)
      params[field_name].delete(parent_id.to_s)
      params[field_name] -= children_ids if children_ids
      params
    else
      params.except(field_name)
    end
  end
end
