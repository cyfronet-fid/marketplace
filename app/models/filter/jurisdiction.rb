# frozen_string_literal: true

class Filter::Jurisdiction < Filter::Multiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "jurisdiction",
      title: "Jurisdiction",
      model: Vocabulary::Jurisdiction,
      index: "jurisdiction"
    )
  end

  protected

  def fetch_options
    @model
      .distinct
      .map { |e| { name: e.name, id: e.eid, count: @counters[e.eid] || 0 } }
      .sort_by! { |e| [-e[:count], e[:name]] }
  end
end
