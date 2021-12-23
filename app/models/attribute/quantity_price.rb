# frozen_string_literal: true

require "json-schema"

class Attribute::QuantityPrice < Attribute
  def value_type_schema
    { type: "string", enum: ["integer"] }
  end

  def config_schema
    {
      type: "object",
      required: %w[start_price step_price currency],
      properties: {
        start_price: {
          type: "integer",
          minimum: 0
        },
        step_price: {
          type: "integer",
          minimum: 0
        },
        currency: {
          type: "string"
        },
        max: {
          type: "integer",
          minimum: 0
        }
      }
    }
  end

  def value_validity
    super

    errors.add(:id, "Quantity need to be greater or equal to 0") if to_small?
    errors.add(:id, "Quantity need to be lower or equal to #{max}") if to_big?
  end

  def value_type
    "integer"
  end

  def value_valid?
    Integer(@value)
  rescue StandardError
    false
  end

  def start_price
    config["start_price"]
  end

  def step_price
    config["step_price"]
  end

  def max
    config["max"]
  end

  def currency
    config["currency"]
  end

  TYPE = "quantity_price"

  private

  def to_small?
    value&.negative?
  end

  def to_big?
    value && max && value > max
  end
end
