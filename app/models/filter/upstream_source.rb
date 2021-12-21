# frozen_string_literal: true

class Filter::UpstreamSource < Filter
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "source",
      type: :select,
      title: "Source catalogue",
      index: "source"
    )
  end

  private

  def fetch_options
    [{ name: "Any", id: "" }, { name: "Internal", id: "mp" }, { name: "EOSC Registry", id: "eosc_registry" }]
  end

  def where_constraint
    value == "mp" ? { @index.to_sym => nil } : { @index.to_sym => value }
  end
end
