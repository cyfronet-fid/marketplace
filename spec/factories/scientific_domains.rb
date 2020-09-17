# frozen_string_literal: true

FactoryBot.define do
  factory :scientific_domain do
    sequence(:name) { |n| "scientific domain %05d" % n }
    sequence(:eid) { |n| "scientific_domain-sd#{n}" }
  end
end
