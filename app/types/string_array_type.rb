# frozen_string_literal: true

class StringArrayType < ActiveModel::Type::Value
  attr_reader :delimiter


  def initialize(delimiter = ",")
    @delimiter = delimiter
  end

  def cast(value)
    if value.is_a?(::String)
      value = value.split(@delimiter).map { |v| v.strip }
    end
    value
  end
end
