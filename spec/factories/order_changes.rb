# frozen_string_literal: true

FactoryBot.define do
  factory :project_item_change do
    status { :created }
    sequence(:message) { |n| "project_item change #{n} message" }
    project_item
  end
end
