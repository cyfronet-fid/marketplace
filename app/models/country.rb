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

    def load(json)
      return nil if json.blank?
      if json.is_a? Array
        json.map { |e| Country.for(JSON.parse(e)) }
      else
        Country.for(JSON.parse(json))
      end
    end

    def dump(obj)
      return nil if obj.blank?
      if obj.is_a? Array
        obj.map(&:alpha2).map(&:to_json) unless obj.any? { |c| c.nil? }
      else
        obj.alpha2.to_json
      end
    end

    def european_countries
      ISO3166::Country.find_all_countries_by_region("Europe").sort
    end
  end
end
