# frozen_string_literal: true

class Parameter::Range < Parameter
  attribute :min, :integer
  attribute :max, :integer
  attribute :exclusive_min, :boolean
  attribute :exclusive_max, :boolean
  attribute :unit, :string

  validates :min, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validate do
    if min && max && min >= max
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
