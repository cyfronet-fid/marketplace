# frozen_string_literal: true

class Country
  NON_EUROPEAN = ["non-European", "N/E"]
  INTERNATIONAL = ["International", "I/N"]
  NON_APPLICABLE = ["non-applicable", "N/A"]

  def self.customer_countries_list
    get_countries(NON_EUROPEAN)
  end

  def self.countries_list
    get_countries(INTERNATIONAL, NON_EUROPEAN)
  end

  def self.validator_countries_list
    [NON_APPLICABLE[1], INTERNATIONAL[1], NON_EUROPEAN[1]] +
        ISO3166::Country.find_all_countries_by_region("Europe").sort.map { |c| c.alpha2 }
  end

  def self.get_countries(*extra)
    extra + ISO3166::Country.find_all_countries_by_region("Europe").sort.map { |c| [c.name, c.alpha2] }
  end
end
