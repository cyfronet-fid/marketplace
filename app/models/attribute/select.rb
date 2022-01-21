# frozen_string_literal: true

require "json-schema"

class Attribute::Select < Attribute
  def value_valid?
    proper_type_value = value_schema[:type] == "string" ? "\"#{value}\"" : value
    JSON::Validator.validate(value_schema, proper_type_value) && config["values"].include?(value)
  end

  def config_schema
    {
      type: "object",
      properties: {
        values: {
          type: "array",
          items: @value_type
        },
        mode: {
          type: "string",
          enum: %w[dropdown buttons]
        }
      }
    }
  end

  def value_from_param(param)
    param = param.reject(&:blank?)
    unless param.empty?
      case @value_type
      when "integer"
        @value =
          begin
            Integer(param.first)
          rescue StandardError
            param.first
          end
      else
        @value = param.first
      end
    end
  end

  TYPE = "select"
end
