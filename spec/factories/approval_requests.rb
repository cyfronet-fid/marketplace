# frozen_string_literal: true

FactoryBot.define do
  factory :approval_request do
    approvable { association(:provider, status: :unpublished) }
    user
    status { :published }

    trait :accepted do
      status { :deleted }
      last_action { :accepted }
    end

    trait :rejected do
      status { :deleted }
      last_action { :rejected }
    end

    trait :changes_requested do
      last_action { :requested_for_changes }
    end
  end
end
