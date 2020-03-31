# frozen_string_literal: true

class Parameter::Constant < Parameter
  attribute :value
  attribute :value_type, :string

  validates :value, presence: true
  validates :value_type, presence: true, inclusion: %w[string integer]
  validate :correct_value_type

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id, type: type, label: name, description: hint,
      value: value, value_type: value_type)
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        value: hsh["value"], value_type: hsh["value_type"])
  end

  def self.type
    "attribute"
  end

  private
    def correct_value_type
      Integer(value) if value_type == "integer"
    rescue
      errors.add(:value, "is not an integer")
    end
end
