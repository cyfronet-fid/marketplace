# frozen_string_literal: true

FactoryBot.define do
  factory :project_item do
    status :created
    service
    project

    factory :open_access_project_item do
      status :ready
    end
  end
end
