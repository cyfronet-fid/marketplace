# frozen_string_literal: true

class Parameter::Date < Parameter
  def dump
    ActiveSupport::HashWithIndifferentAccess.new(
      id: id,
      type: type,
      label: name,
      description: hint,
      value_type: "string"
    )
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"])
  end
end
