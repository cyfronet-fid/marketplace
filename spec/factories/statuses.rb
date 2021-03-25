# frozen_string_literal: true

FactoryBot.define do
  factory :status do
    status { "created" }
    status_type { :created }
    association(:status_holder, factory: :project_item)
  end
end
