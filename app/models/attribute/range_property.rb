# frozen_string_literal: true

require "json-schema"

class Attribute::RangeProperty < Attribute
  def value_schema
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
        }
    }
  end

  def value_from_param(param)
    raise "not implemented yet"
  end

  protected
    TYPE = "range-property"
end
