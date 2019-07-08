# frozen_string_literal: true

FactoryBot.define do
  factory :tatus do
    value { :created }
    association(:pipeline, factory: :project_item)
  end
end
