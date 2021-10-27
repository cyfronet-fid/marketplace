# frozen_string_literal: true

class ArrayType < ActiveModel::Type::Value
  attr_reader :delimiter

  def initialize(delimiter = ",")
    super()
    @delimiter = delimiter
  end

  def cast(value)
    value = value.split(@delimiter).map(&:strip) if value.is_a?(::String)
    value
  end
end
