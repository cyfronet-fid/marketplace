# frozen_string_literal: true

# Used to show countries list in the front
module CountriesHelper
  NON_EUROPEAN = ["non-European", "N/E"]
  INTERNATIONAL = ["International", "I/N"]
  NON_APPLICABLE = ["non-applicable", "N/A"]

  def customer_countries
    countries(NON_EUROPEAN)
  end

  def collaboration_countries
    countries(INTERNATIONAL, NON_EUROPEAN)
  end

  def country_name(codes)
    if codes.is_a? Array
      codes.map { |code| collaboration_countries.rassoc(code).first }
    elsif codes.is_a? String
      collaboration_countries.rassoc(codes).first
    else
      nil
    end
  end

  def countries(*extra)
    extra + ISO3166::Country.find_all_countries_by_region("Europe").sort.map { |c| [c.name, c.alpha2] }
  end
end
