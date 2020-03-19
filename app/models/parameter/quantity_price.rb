# frozen_string_literal: true

class Parameter::QuantityPrice < Parameter
  attr_accessor :start_price, :step_price, :unit, :max

  validates :start_price, numericality: { greater_than_or_equal_to: 0 }
  validates :step_price, numericality: { greater_than_or_equal_to: 0 }
  validates :max, numericality: { greater_than: 0, allow_nil: true }
  validates :unit, presence: true
end
