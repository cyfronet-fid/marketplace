# frozen_string_literal: true

class Filter::Location < Filter
  #   TODO finish this filter

  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "location", type: :select,
          title: "Provider location", index: nil)
  end

  private
    def fetch_options
      [{ name: "Any", id: "" }, { name: "EU", id: "EU" }]
    end

    def where_constraint
      {}  # TODO finish this filter
    end
end
