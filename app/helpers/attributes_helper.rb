# frozen_string_literal: true

# Used to convert Postgres JSON to list of elements, which can be rendered
# in views
module AttributesHelper
  def parse_offer_parameter_value(parameter)
    return unless parameter

    value =
      if parameter["value"]
        parameter["value"] # .to_s if needed
      elsif parameter["type"] == "input"
        parameter["value_type"].to_s
      elsif parameter["type"] == "date"
        parameter["type"].to_s
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

  def hideable_options(index)
    index > 3 ? { class: "d-none", data: { "parameter-target": "hideableParameter", state: "hidden" } } : {}
  end

  def render_default_parameters(form, parameters)
    parameters.each_with_index { |p, idx| render "parameters/template", parameter: p, form: form, index: idx }
  end

  private

  def from_to(from, to)
    "#{from || "?"} - #{to || "?"}"
  end
end
