# frozen_string_literal: true

require "json-schema"

class Attribute::RangeProperty < Attribute
  def value_schema
    {
      type: "object",
      required: %w[minimum maximum],
      properties: {
        minimum: {
          type: @value_type
        },
        maximum: {
          type: @value_type
        }
      }
    }
  end

  def value_from_param(_param)
    raise "not implemented yet"
  end

  TYPE = "range-property"
end
