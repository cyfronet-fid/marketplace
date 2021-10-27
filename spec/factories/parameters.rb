# frozen_string_literal: true

FactoryBot.define do
  factory :parameter, class: "Parameter" do
    sequence(:id, &:to_s)
    hint { "description" }
    initialize_with { new(attributes) }
  end

  factory :constant_parameter, class: "Parameter::Constant", parent: :parameter do
    sequence(:name) { |n| "constant parameter #{n}" }
    sequence(:value) { |n| "value #{n}" }
    value_type { "string" }
  end

  factory :input_parameter, class: "Parameter::Input", parent: :parameter do
    sequence(:name) { |n| "input parameter #{n}" }
    value_type { "string" }
  end

  factory :select_parameter, class: "Parameter::Select", parent: :parameter do
    sequence(:name) { |n| "select parameter #{n}" }
    value_type { "string" }
    values { %w[a b c] }
    mode { "buttons" }
  end

  factory :multiselect_parameter, class: "Parameter::Multiselect", parent: :parameter do
    sequence(:name) { |n| "multiselect parameter #{n}" }
    value_type { "string" }
    values { %w[a b c d] }
    minItems { 1 }
    maxItems { 3 }
  end

  factory :range_parameter, class: "Parameter::Range", parent: :parameter do
    sequence(:name) { |n| "range parameter #{n}" }
    min { 1 }
    max { 255 }
    exclusive_min { false }
    exclusive_max { false }
    unit { "" }
  end

  factory :quantity_price_parameter, class: "Parameter::QuantityPrice", parent: :parameter do
    sequence(:name) { |n| "quantity_price parameter #{n}" }
    start_price { 1000 }
    step_price { 100 }
    currency { "EUR" }
    max { 15 }
  end

  factory :date_parameter, class: "Parameter::Date", parent: :parameter do
    sequence(:name) { |n| "date parameter #{n}" }
    value_type { "string" }
  end
end
