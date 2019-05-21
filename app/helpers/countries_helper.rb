# frozen_string_literal: true

module CountriesHelper
  def customer_countries_list
    result = ["non-European"]
    countries.each do |country|
      result << country.name
    end
    @countries = result
  end

  def countries_list
    result = ["International", "non-European"]
    countries.each do |country|
      result << country.name.to_s
    end
    @countries = result
  end

  def countries
    ISO3166::Country.find_all_countries_by_region("Europe").sort
  end
end
