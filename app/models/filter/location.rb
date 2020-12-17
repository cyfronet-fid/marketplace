# frozen_string_literal: true

class Filter::Location < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "geographical_availabilities",
          title: "Provider location",
          type: :select,
          index: "geographical_availabilities")
  end

  private
    def fetch_options
      [{ name: "Any", id: "" }] + Service.where(status: [:published, :unverified])
             .pluck(:geographical_availabilities).flatten.uniq.map { |s| { name: s, id: s } }
    end

    def where_constraint
      { @index.to_sym => values.map { |c| Country.dump(Country.find_by_name(c)) } }
    end
end
