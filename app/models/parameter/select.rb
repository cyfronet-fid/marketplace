# frozen_string_literal: true

class Parameter::Select < Parameter
  include Parameter::Values

  attribute :mode, :string
  attribute :unit, :string

  validates :mode, presence: true, inclusion: %w[dropdown buttons]

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      config: {
        values: cast(values),
        mode: mode
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
      mode: hsh.dig("config", "mode"),
      value_type: hsh["value_type"],
      unit: hsh["unit"]
    )
  end
end
