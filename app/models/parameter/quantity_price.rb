# frozen_string_literal: true

class Parameter::QuantityPrice < Parameter
  attribute :start_price, :integer
  attribute :step_price, :integer
  attribute :max, :integer
  attribute :currency, :string

  validates :start_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :step_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max, numericality: { greater_than: 0, allow_nil: true }
  validates :currency, presence: true

  def dump
    ActiveSupport::HashWithIndifferentAccess.new(id: id, type: "quantity_price", label: name, description: hint,
                                                 config: { start_price: start_price,
                                                           step_price: step_price,
                                                           max: max,
                                                           currency: currency },
                                                 value_type: "integer")
  end

  def self.load(hsh)
    new(id: hsh["id"], name: hsh["label"], hint: hsh["description"],
        start_price: hsh.dig("config", "start_price"), step_price: hsh.dig("config", "step_price"),
        max: hsh.dig("config", "max"), currency: hsh.dig("config", "currency"))
  end
end
