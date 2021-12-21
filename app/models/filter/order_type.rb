# frozen_string_literal: true

class Filter::OrderType < Filter
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "order_type",
      title: "Order type",
      type: :select,
      index: "order_type"
    )
  end

  protected

  def fetch_options
    [
      { name: "Any", id: "" },
      { name: "Open Access", id: "open_access" },
      { name: "Fully open access", id: "fully_open_access" },
      { name: "Order required", id: "order_required" },
      { name: "Other", id: "other" }
    ]
  end

  def where_constraint
    { @index.to_sym => values }
  end
end
