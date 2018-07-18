# frozen_string_literal: true

FactoryBot.define do
  factory :question, class: Order::Question do
    sequence(:text) { |n| "question #{n} message" }
    order
    to_create { |instance| Order::Question::Create.new(instance) }
  end
end
