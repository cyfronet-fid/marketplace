# frozen_string_literal: true

class Country
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

  class << self
    def for(value)
      return value if value.is_a?(ISO3166::Country)
      ISO3166::Country.new(value)
    end

    def load(code)
      return nil if code.blank?
      code.is_a?(Array) ? code.map { |c| Country.for(c) } : Country.for(code)
    end

    def dump(obj)
      return nil if obj.blank?
      obj.is_a?(Array) ? obj.map { |o| o.alpha2 } : obj.alpha2
    end

    def european_countries
      ISO3166::Country.find_all_countries_by_region("Europe").sort
    end
  end
end
