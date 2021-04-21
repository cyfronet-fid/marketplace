# frozen_string_literal: true

class Parameter::Multiselect < Parameter
  include Parameter::Values
  include Parameter::Minmax

  attribute :unit, :string

  validates :min, numericality: { greater_than: 0,  less_than_or_equal_to: ->(p) { p.values&.length || 1 } }
  validates :max, numericality: { greater_than: 0, less_than_or_equal_to: ->(p) { p.values&.length || 1 } }
  validate :duplicates, if: :values

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: type, label: name, description: hint,
      config: { values: cast(values), minItems: (min || 1), maxItems: (max || values.length) },
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
