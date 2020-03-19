# frozen_string_literal: true

class AttributeTemplate::QuantityPrice < AttributeTemplate
  attr_accessor :start_price, :step_price, :unit, :max

  validates :start_price, numericality: { greater_than_or_equal_to: 0 }
  validates :step_price, numericality: { greater_than_or_equal_to: 0 }
  validates :max, numericality: { greater_than: 0, allow_nil: true }
  validates :unit, presence: true

  def to_attribute
    Attribute::QuantityPrice.new.tap do |attr|
      attr.id = id
      attr.label = name
      attr.description = hint
    end
  end
end
