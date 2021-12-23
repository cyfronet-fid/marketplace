# frozen_string_literal: true

require "json-schema"

class Attribute::Multiselect < Attribute::Select
  def value_valid?
    JSON::Validator.validate(value_schema, value) && value.all? { |v| config["values"].include?(v) }
  end

  def config_schema
    { type: "object", properties: { values: { type: "array", items: @value_type }, minItems: { type: "integer" } } }
  end

  def value_schema
    {
      type: "array",
      items: {
        type: @value_type
      },
      minItems: config["minItems"] || 0,
      maxItems: config["maxItems"] || config["values"].size
    }
  end

  def value_from_param(param)
    param = param.reject(&:blank?)
    case @value_type
    when "integer"
      @value = param.map { |p| Integer(p) }
    else
      @value = param
    end
  end

  TYPE = "multiselect"
end
