# frozen_string_literal: true

require "json-schema"

class Attribute::Input < Attribute
  def value_valid?
    JSON::Validator.validate(value_schema, value, parse_data: false)
  end

  protected

    TYPE = "input"
end
