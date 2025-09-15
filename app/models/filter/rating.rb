# frozen_string_literal: true

class Filter::Rating < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}), field_name: "rating", type: :select, title: "Rating", index: "rating")
  end

  protected

  # Accept only numeric values in the 1..5 range to avoid ES number_format_exception
  def values
    super.select { |v| v.to_s.match?(/\A[1-5]\z/) }.map(&:to_s)
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
    v = values.first
    return {} if v.nil?

    { @index.to_sym => { gte: v.to_i } }
  end
end
