# frozen_string_literal: true

class Country
  SCHENGEN = ["AT", "BE", "CH", "CZ", "DE", "DK",
              "EE", "GR", "ES", "FI", "FR", "HU",
              "IS", "IT", "LI", "LT", "LU", "LV",
              "MT", "NL", "NO", "PL", "PT", "SE", "SI", "SK"].freeze

  ISO3166::Data.register(
    alpha2: "WW",
    name: "World",
    translations: {
        "en" => "Worldwide"
    })

  ISO3166::Data.register(
    alpha2: "EO",
    name: "Europe",
    translations: {
        "en" => "Europe"
    })

  ISO3166::Data.register(
    alpha2: "EU",
    name: "European Union",
    translations: {
        "en" => "European Union"
    })

  ISO3166::Data.register(
    alpha2: "EZ",
    name: "Euro Zone",
    translations: {
        "en" => "Euro Zone"
    })

  ISO3166::Data.register(
    alpha2: "AH",
    name: "Schengen Area",
    translations: {
        "en" => "Schengen Area"
    })

  ISO3166::Data.register(
    alpha2: "N/E",
    name: "non-European",
    translations: {
        "en" => "non-European"
    })

  class << self
    def for(value)
      return value if value.is_a?(ISO3166::Country)
      ISO3166::Country.new(value)
    end

    def load(code)
      return nil if code.blank?
      Country.for(code)
    end

    def dump(obj)
      return nil if obj.blank?
      obj.alpha2
    end

    def all
      @all ||= (ISO3166::Country.find_all_countries_by_region("Europe") +
                [ISO3166::Country.new("N/E")]).sort
    end

    def options
      ISO3166::Country.all
    end

    def countries_for_region(region)
      if region == "World"
        Country.world
      elsif region == "European Union"
        Country.european_union
      elsif region == "Schengen Area"
        Country.schengen_area
      elsif region == "Europe"
        ISO3166::Country.find_all_countries_by_region("Europe")
      elsif region == "Euro Zone"
        ISO3166::Country.find_all_countries_by_currency_code("EUR").select { |c| c.in_eu? }
      else
        ISO3166::Country.find_all_countries_by_region(region)
      end
    end

    def european_union
      ISO3166::Country.all.select { |c| c.in_eu? }
    end

    def world
      ISO3166::Country.all
    end

    def find_by_name(name)
      ISO3166::Country.find_country_by_name(name)
    end

    def schengen_area
      Country::SCHENGEN.map { |p| ISO3166::Country.new(p) }
    end
  end

  class Array
    class << self
      def load(code)
        return nil if code.blank?
        code.map { |c| Country.for(c) }
      end

      def dump(obj)
        return nil if obj.blank?
        obj.compact.map { |o| o.alpha2 }
      end
    end
  end
end
