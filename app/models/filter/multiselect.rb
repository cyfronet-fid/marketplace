# frozen_string_literal: true

class Filter::Multiselect < Filter
  def initialize(params:, title:, field_name:, model:, index:, search: false)
    super(params: params, field_name: field_name, type: :multiselect, title: title, index: index)
    @model = model
    @search = search
  end

  def search?
    @search
  end

  protected

  def fetch_options
    @model
      .distinct
      .map { |e| { name: e.name, id: e.id, count: @counters[e.id] || 0 } }
      .sort_by! { |e| [-e[:count], e[:name]] }
  end

  def where_constraint
    { @index.to_sym => values }
  end
end
