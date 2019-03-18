# frozen_string_literal: true

require "json-schema"

class Attribute::Select < Attribute
  def value_valid?
    JSON::Validator.validate(value_schema, value) && config["values"].include?(value)
  end

  def config_schema
    {
        "type": "object",
        "properties": {
            "values": {
                "type": "array",
                "items": @value_type
            },
            "mode": {
                "type": "string",
                "enum": ["dropdown", "buttons"]
            }
        }
    }
  end

  def value_from_param(param)
    param = param.reject(&:blank?)
    if (param.length > 0)
      case @value_type
      when "integer"
        @value = Integer(param.first) rescue param.first
      else
        @value = param.first
      end
    end
  end

  protected
    TYPE = "select"
end
