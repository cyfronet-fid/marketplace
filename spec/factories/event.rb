# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    action { "create" }
    eventable { build(:project_item) }
  end
end
