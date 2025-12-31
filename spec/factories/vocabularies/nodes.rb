# frozen_string_literal: true

FactoryBot.define do
  factory :node, class: "vocabulary/node" do
    sequence(:name) { |n| "Node #{n}" }
    sequence(:eid) { |n| "node-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
