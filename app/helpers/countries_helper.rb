# frozen_string_literal: true

# Used to show countries list in the front
module CountriesHelper
  ISO3166::Data.register(
    alpha2: "N/E",
    name: "non-European",
    translations: {
        "en" => "non-European"
    })

  ISO3166::Data.register(
    alpha2: "I/N",
    name: "International",
    translations: {
        "en" => "International"
    })

  ISO3166::Data.register(
    alpha2: "N/A",
    name: "non-applicable",
    translations: {
        "en" => "non-applicable"
    })

  NON_EUROPEAN = ISO3166::Country.new("N/E")
  INTERNATIONAL = ISO3166::Country.new("I/N")
  NON_APPLICABLE = ISO3166::Country.new("N/A")

  def customer_countries
    countries(NON_EUROPEAN)
  end

  def collaboration_countries
    countries(INTERNATIONAL, NON_EUROPEAN)
  end

  def allowed_countries
    countries(NON_EUROPEAN, INTERNATIONAL, NON_APPLICABLE)
  end

  def self.parse_json(country)
    ISO3166::Country.new(JSON.parse(country)["country_data_or_code"])
  end

  def country_name(countries)
    if countries.is_a? Array
      result = []
      countries.each do |country|
        obj = JSON.parse(country)
        result += obj["country_data_or_code"]["name"]
      end

      result
    elsif codes.is_a? String
      obj = JSON.parse(codes)
      obj["country_data_or_code"]["name"]
    else
      nil
    end
  end

  def countries(*extra)
    extra + ISO3166::Country.find_all_countries_by_region("Europe").sort
  end
end
