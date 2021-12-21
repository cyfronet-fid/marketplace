# frozen_string_literal: true

class Parameter::Range < Parameter
  include Parameter::Minmax

  attribute :exclusive_min, :boolean
  attribute :exclusive_max, :boolean
  attribute :unit, :string

  validates :min, presence: true
  validates :max, presence: true

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      unit: unit,
      value_type: "integer",
      config: {
        minimum: min,
        maximum: max,
        exclusiveMinimum: exclusive_min,
        exclusiveMaximum: exclusive_max
      }
    )
  end

  def self.load(hsh)
    new(
      id: hsh["id"],
      name: hsh["label"],
      hint: hsh["description"],
      unit: hsh["unit"],
      min: hsh.dig("config", "minimum"),
      max: hsh.dig("config", "maximum"),
      exclusive_min: hsh.dig("config", "exclusiveMinimum"),
      exclusive_max: hsh.dig("config", "exclusiveMaximum")
    )
  end
end
