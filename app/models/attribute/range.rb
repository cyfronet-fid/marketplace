# frozen_string_literal: true

require "json-schema"

class Attribute::Range < Attribute
  def value_type_schema
    {
        "type": "string",
        "enum": ["integer"]
    }
  end

  def value_schema
    {
        "type": @value_type,
        "minimum": config["minimum"],
        "maximum": config["maximum"],
        "exclusiveMinimum": config["exclusiveMinimum"] || false,
        "exclusiveMaximum": config["exclusiveMaximum"] || false,
    }
  end

  def value_from_param(param)
    if !param.blank?
      case value_type
      when "integer"
        @value = Integer(param) rescue String(param)
      else
        @value = param
      end
    end
  end

  def config_schema
    {
        "type": "object",
        "required": ["minimum", "maximum"],
        "properties": {
            "minimum": {
                "type": @value_type
            },
            "maximum": {
                "type": @value_type
            },
            "exclusiveMinimum": {
                "type": "boolean"
            },
            "exclusiveMaximum": {
                "type": "boolean"
            }
        }
    }
  end

  protected
    TYPE = "range"
end
