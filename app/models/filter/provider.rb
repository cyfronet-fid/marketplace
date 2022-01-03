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

  protected

  def fetch_options
    @model
      .distinct
      .filter_map { |e| { name: e.name, id: e.id, count: @counters[e.id] || 0 } unless e.deleted? || e.draft? }
      .sort_by! { |e| [-e[:count], e[:name]] }
  end
end
