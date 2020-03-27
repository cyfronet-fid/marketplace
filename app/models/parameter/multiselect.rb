# frozen_string_literal: true

class Parameter::Multiselect < Parameter
  include Parameter::Values

  attribute :min, :integer
  attribute :max, :integer
  attribute :unit, :string

  validates :min, numericality: { less_than_or_equal_to: ->(p) { p.max } }
  validates :min, numericality: { less_than_or_equal_to: ->(p) { p.values&.length || 0 } }
  validates :max, numericality: { greater_than_or_equal_to: ->(p) { p.min } }
  validates :max, numericality: { less_than_or_equal_to: ->(p) { p.values&.length || 0 } }
  validate :duplicates

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: "multiselect", label: name, description: hint,
      config: { values: cast(values), minItems: (min || 0), maxItems: (max || values.length) },
      value_type: value_type, unit: unit)
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        values: hsh.dig("config", "values"), min: hsh.dig("config", "minItems"),
        value_type: hsh["value_type"], max: hsh.dig("config", "maxItems"), unit: hsh["unit"])
  end

  private
    def duplicates
      if values.uniq.length != values.length
        errors.add(:values, "there are duplicate elements")
      end
    end
end
