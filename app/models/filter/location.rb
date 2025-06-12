# frozen_string_literal: true

class Filter::Location < Filter
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "geographical_availabilities",
      title: "Service availability",
      type: :select,
      index: "geographical_availabilities"
    )
  end

  private

  def fetch_options
    [{ name: "Any", id: "" }] +
      Service
        .where(status: :published)
        .pluck(:geographical_availabilities)
        .flatten
        .uniq
        .sort
        .map { |s| { name: s, id: s } }
  end

  def where_constraint
    { @index.to_sym => Country.convert(value) }
  end
end
