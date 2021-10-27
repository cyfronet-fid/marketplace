# frozen_string_literal: true

require "json-schema"

class Attribute::Range < Attribute
  def value_type_schema
    {
      type: "string",
      enum: ["integer"]
    }
  end

  def value_schema
    {
      type: @value_type,
      minimum: config["minimum"],
      maximum: config["maximum"],
      exclusiveMinimum: config["exclusiveMinimum"] || false,
      exclusiveMaximum: config["exclusiveMaximum"] || false
    }
  end

  def value_from_param(param)
    return if param.blank?

    @value = case value_type
             when "integer"
               begin
                 Integer(param)
               rescue StandardError
                 String(param)
               end
             else
               param
             end
  end

  def config_schema
    {
      type: "object",
      required: %w[minimum maximum],
      properties: {
        minimum: {
          type: @value_type
        },
        maximum: {
          type: @value_type
        },
        exclusiveMinimum: {
          type: "boolean"
        },
        exclusiveMaximum: {
          type: "boolean"
        }
      }
    }
  end

  TYPE = "range"
end
