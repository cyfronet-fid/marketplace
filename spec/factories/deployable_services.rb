# frozen_string_literal: true

FactoryBot.define do
  factory :deployable_service do
    sequence(:name) { |n| "Deployable Service #{n}" }
    sequence(:abbreviation) { |n| "ds-#{n}" }
    sequence(:description) { |n| "Description for deployable service #{n}" }
    sequence(:tagline) { |n| "Tagline for deployable service #{n}" }
    sequence(:url) { |n| "https://deployable-service-#{n}.example.com" }
    sequence(:node) { %w[docker kubernetes vm].sample }
    sequence(:version) { |n| "#{n}.0.0" }
    sequence(:license_name) { %w[MIT Apache-2.0 GPL-3.0 BSD-3-Clause].sample }
    sequence(:license_url) { |n| "https://licenses.example.com/#{n}" }
    urls { [url] }
    public_contact_emails { ["deployable@example.com"] }
    publishing_date { Date.new(2026, 4, 15) }
    resource_type { "DeployableApplication" }
    sequence(:pid) { |n| "deployable.service.#{n}" }
    creators { ["Creator One", "Creator Two"] }
    association :resource_organisation, factory: :provider
    status { :published }

    trait :with_catalogue do
      association :catalogue
    end

    trait :with_scientific_domains do
      after(:build) { |deployable_service| deployable_service.scientific_domains = create_list(:scientific_domain, 2) }
    end

    trait :draft do
      status { :draft }
    end

    trait :with_tags do
      tag_list { %w[tag1 tag2 tag3] }
    end

    trait :with_node do
      transient { node_vocabulary { create(:node) } }
      node { node_vocabulary.eid }
    end
  end
end
