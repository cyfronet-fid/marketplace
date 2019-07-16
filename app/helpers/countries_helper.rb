# frozen_string_literal: true

# Used to show countries list in the front
module CountriesHelper
  def customer_countries
    [Country::NON_EUROPEAN] + Country.european_countries
  end

  def collaboration_countries
    [Country::INTERNATIONAL, Country::NON_EUROPEAN] + Country.european_countries
  end

  def allowed_countries
    [Country::NON_EUROPEAN, Country::INTERNATIONAL, Country::NON_APPLICABLE] + Country.european_countries
  end
end
