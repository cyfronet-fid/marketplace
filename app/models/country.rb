# frozen_string_literal: true

class Country
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

    def where(opts)
      if opts[:region]
        for_region(opts[:region])
      elsif opts[:name]
        [Country.find_by_name(opts[:name])]
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

    private
      def for_region(region)
        if region == "World"
          Country.world
        elsif region == "Europe"
          Country.european_union
        else
          ISO3166::Country.find_all_countries_by_region(region)
        end
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
