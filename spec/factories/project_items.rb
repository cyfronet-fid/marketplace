# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status :created
    offer
    project
  end
end
