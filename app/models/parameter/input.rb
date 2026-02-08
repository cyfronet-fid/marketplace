# frozen_string_literal: true

class Parameter::Input < Parameter
  attribute :unit, :string
  attribute :value_type, :string
  attribute :sensitive, :boolean, default: false

  validates :value_type, presence: true, inclusion: %w[string integer]

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      unit: unit,
      value_type: value_type,
      sensitive: sensitive
    )
  end

  def self.load(hsh)
    new(
      id: hsh["id"],
      name: hsh["label"],
      hint: hsh["description"],
      unit: hsh["unit"],
      value_type: hsh["value_type"],
      sensitive: hsh["sensitive"]
    )
  end
end
