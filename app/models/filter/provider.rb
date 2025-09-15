# frozen_string_literal: true

class Filter::Provider < Filter::Multiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "providers",
      title: "Providers",
      model: ::Provider,
      index: "providers",
      search: true
    )
  end

  def values
    super.select { |v| v.to_s.match?(/\A\d+\z/) }.map(&:to_s)
  end

  protected

  def where_constraint
    ids = values.map(&:to_i)
    return {} if ids.empty?

    { @index.to_sym => ids }
  end

  def fetch_options
    @model
      .distinct
      .filter_map { |e| { name: e.name, id: e.id, count: @counters[e.id] || 0 } unless e.deleted? || e.draft? }
      .sort_by! { |e| [-e[:count], e[:name]] }
  end
end
