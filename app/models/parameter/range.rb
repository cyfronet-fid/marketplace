# frozen_string_literal: true

class Parameter::Range < Parameter
  attr_accessor :min, :max, :exclusive_min, :exclusive_max, :unit

  validates :min, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max, presence: true, numericality: { greater_than_or_equal_to: 0 }
  # validates :exclusive_min, inclusion: { in: [ true, false ] }
  # validates :exclusive_max, inclusion: { in: [ true, false ] }

  validate do
    if min >= max
      errors.add(:min, "must be less than maximum value")
      errors.add(:max, "must be greater than minimum value")
    end
  end

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: "range", label: name, description: hint, unit: unit,
      value_type: "integer",
      config: {
        minimum: min, maximum: max,
        exclusiveMinimum: exclusive_min, exclusiveMaximum: exclusive_max
      }
    )
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"], unit: hsh["unit"],
        min: hsh.dig("config", "minimum"), max: hsh.dig("config", "maximum"),
        exclusive_min: hsh.dig("config", "exclusiveMinimum"),
        exclusive_max: hsh.dig("config", "exclusiveMaximum"))
  end
end
