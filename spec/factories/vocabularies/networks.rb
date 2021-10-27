# frozen_string_literal: true

FactoryBot.define do
  factory :network, class: "vocabulary/network" do
    sequence(:name) { |n| "Network #{n}" }
    sequence(:eid) { |n| "provider_network-#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:extras) { |_n| {} }
  end
end
