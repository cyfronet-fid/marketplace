# frozen_string_literal: true

class Filter::Rating < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}), field_name: "rating", type: :select, title: "Rating", index: "rating")
  end

  private

  def fetch_options
    [
      { name: "Any", id: "" },
      { name: "★+", id: "1" },
      { name: "★★+", id: "2" },
      { name: "★★★+", id: "3" },
      { name: "★★★★+", id: "4" },
      { name: "★★★★★", id: "5" }
    ]
  end

  def where_constraint
    { @index.to_sym => { gte: value } }
  end
end
