# frozen_string_literal: true

class Filter::OrderType < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "service_type",
          title: "Order type",
          type: :select,
          index: "service_type")
  end

  protected
    def fetch_options
      [
          { name: "Any", id: "" },
          { name: "Open Access", id: "open_access" },
          { name: "Internal ordering", id: "orderable" },
          { name: "External ordering", id: "external" }
      ]
    end

    def where_constraint
      { @index.to_sym => values }
    end
end
