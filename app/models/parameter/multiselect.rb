# frozen_string_literal: true

class Parameter::Multiselect < Parameter
  include Parameter::Values
  include Parameter::Minmax

  attribute :unit, :string

  validates :min, numericality: { greater_than: 0 }
  validates :max, numericality: { greater_than: 0 }

  validates :min, numericality: { less_than_or_equal_to: ->(p) { p.values&.length || 1 } }, if: :values_and_max?
  validates :max, numericality: { less_than_or_equal_to: ->(p) { p.values&.length || 1 } }, if: :values_and_min?

  validate :duplicates, if: :values

  def values_and_min?
    values.present? && min.present?
  end

  def values_and_max?
    values.present? && min.present?
  end

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      config: {
        values: cast(values),
        minItems: min || 1,
        maxItems: max || values.length
      },
      value_type: value_type,
      unit: unit
    )
  end

  def self.load(hsh)
    new(
      id: hsh["id"],
      name: hsh["label"],
      hint: hsh["description"],
      values: hsh.dig("config", "values"),
      min: hsh.dig("config", "minItems"),
      value_type: hsh["value_type"],
      max: hsh.dig("config", "maxItems"),
      unit: hsh["unit"]
    )
  end

  private

  def duplicates
    errors.add(:values, "there are duplicate elements") if values.uniq.length != values.length
  end
end
