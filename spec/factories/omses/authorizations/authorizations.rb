# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_basic, class: OMS::Authorization::Basic do
    association :trigger

    user { "name" }
    password { "12341234" }
  end
end
