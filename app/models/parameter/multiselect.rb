# frozen_string_literal: true

class Parameter::Multiselect < Parameter
  attribute :values, :string_array
  attribute :min, :integer, default: 2

  validates :values, presence: true
  validates :min, presence: true
  validate do
    if min && values && min >= values.length
      errors.add(:min, "must be less than number of items")
    end
  end

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: "multiselect", label: name, description: hint,
      config: { values: values, minItems: min }, value_type: "string")
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        values: hsh.dig("config", "values"), min: hsh.dig("config", "minItems"))
  end
end
