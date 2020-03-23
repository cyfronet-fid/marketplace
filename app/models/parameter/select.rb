# frozen_string_literal: true

class Parameter::Select < Parameter
  attribute :values, :string_array
  attribute :mode, :string


  validates :mode, presence: true, inclusion: %w[dropdown buttons]
  validates :values, presence: true


  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: "select", label: name, description: hint,
      config: { values: values, mode: mode }, value_type: "string")
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        values: hsh.dig("config", "values"), mode: hsh.dig("config", "mode"))
  end
end
