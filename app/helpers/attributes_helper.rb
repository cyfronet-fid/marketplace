# frozen_string_literal: true

# Used to convert Postgres JSON to list of elements, which can be rendered
# in views
module AttributesHelper
  EXCLUDED_TYPES = ["date", "input"]

  def filter_technical_parameters(parameters)
    parameters.select do |parameter|
      if EXCLUDED_TYPES.include?(parameter["type"])
        false
      elsif parameter["value_type"] == "string" then
        false
      else
        true
      end
    end
  end

  def parse_offer_parameter_value(parameter)
    return unless parameter

    value = if parameter["value"]
      parameter["value"] # .to_s if needed
    elsif parameter["config"]
      config = parameter["config"]
      if config["minimum"] || config["maximum"]
        from_to(config["minimum"], config["maximum"])
      elsif config["values"]
        from_to(config["values"][0], config["values"][-1])
      end
    end

    "#{value} #{parameter["unit"]}"
  end

  private
    def from_to(from, to)
      "#{from || "?"} - #{to || "?"}"
    end
end
