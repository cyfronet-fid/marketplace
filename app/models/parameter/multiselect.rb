# frozen_string_literal: true

class Parameter::Multiselect < Parameter
  include Parameter::Values

  attribute :min, :integer

  validates :min, presence: true
  validate do
    if min && values && min >= values.length
      errors.add(:min, "must be less than number of items")
    end
  end

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: "multiselect", label: name, description: hint,
      config: { values: cast(values), minItems: (min || 0) },
      value_type: value_type)
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        values: hsh.dig("config", "values"), min: hsh.dig("config", "minItems"),
        value_type: hsh["value_type"])
  end
end
