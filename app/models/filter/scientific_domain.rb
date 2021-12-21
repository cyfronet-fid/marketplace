# frozen_string_literal: true

class Filter::ScientificDomain < Filter::AncestryMultiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "scientific_domains",
      title: "Scientific Domains",
      model: ::ScientificDomain,
      joining_model: ServiceScientificDomain,
      index: "scientific_domains",
      search: true
    )
  end
end
