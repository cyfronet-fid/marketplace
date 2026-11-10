# frozen_string_literal: true

class Parameter::Input < Parameter
  attribute :unit, :string
  attribute :value_type, :string
  attribute :sensitive, :boolean, default: false
  attribute :default_value

  validates :value_type, presence: true, inclusion: %w[string integer]

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      unit: unit,
      value_type: value_type,
      sensitive: sensitive,
      default_value: default_value
    )
  end

  def self.load(hsh)
    new(
      id: hsh["id"],
      name: hsh["label"],
      hint: hsh["description"],
      unit: hsh["unit"],
      value_type: hsh["value_type"],
      sensitive: hsh["sensitive"],
      default_value: hsh["default_value"]
    )
  end
end
