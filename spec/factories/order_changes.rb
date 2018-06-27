# frozen_string_literal: true

FactoryBot.define do
  factory :order_change do
    status :created
    sequence(:message) { |n| "order change #{n} message" }
    order
  end
end
