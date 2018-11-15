# frozen_string_literal: true

# Used to convert Postgres JSON to list of elements, which can be rendered
# in views
module ParseOfferParameterValueHelper
  def parse_offer_parameter_value(parameter)
    if parameter.nil?
      return parameter
    end

    if not parameter["value"].nil?
      return "#{parameter["value"]} #{parameter["unit"]}"
    elsif not parameter["config"].nil? then
      config = parameter["config"]
      if config["minimum"] || config["maximum"]
        return "#{config["minimum"] || "?"} - #{config["maximum"] || "?"} #{parameter["unit"]}"
      elsif not config["values"].nil? then
        return "#{config["values"][0]} - #{config["values"][-1]} #{parameter["unit"]}"
      end
    end
  end
end
