# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:name) { |n| "service #{n}" }
    sequence(:abbreviation) { |n| "service-#{n}" }
    sequence(:description) { |n| "service #{n} description" }
    sequence(:tagline) { |n| "service #{n} tagline" }
    sequence(:order_type) { :order_required }

    factory :open_access_service do
      sequence(:order_type) { :open_access }
    end
    factory :fully_open_access_service do
      sequence(:order_type) { :fully_open_access }
    end
    factory :other_service do
      sequence(:order_type) { :other }
    end
    factory :order_required_service do
      sequence(:order_type) { :order_required }
    end
    factory(:datasource) do
      sequence(:type) { "Datasource" }
      sequence(:version_control) { false }
    end
    sequence(:webpage_url) { "https://wabpage.url" }
    sequence(:manual_url) { "https://manual.url" }
    sequence(:helpdesk_url) { "https://helpdesk.url" }
    sequence(:training_information_url) { "https://tutorial.url" }
    sequence(:terms_of_use_url) { "https://terms.of.use.url" }
    sequence(:resource_level_url) { "https://corporate.sla.url" }
    sequence(:access_policies_url) { "https://access.policies.url" }

    sequence(:language_availability) { [I18nData.languages.values.sample] }
    sequence(:geographical_availabilities) { |_n| ["EU"] }
    sequence(:dedicated_for) { |n| ["service #{n} dedicated for"] }
    sequence(:restrictions) { |n| "service #{n} restrictions" }
    sequence(:scientific_domains) { |_n| [create(:scientific_domain)] }
    sequence(:resource_organisation) { |_n| create(:provider) }
    sequence(:providers) { |_n| [create(:provider)] }
    sequence(:life_cycle_statuses) { |_n| [create(:life_cycle_status)] }
    sequence(:categories) { |_n| [create(:category)] }
    sequence(:status) { :published }
    sequence(:version) { nil }
    sequence(:trls) { [create(:trl)] }
    sequence(:synchronized_at) { Time.now - 2.days }
    sequence(:main_contact) { build(:main_contact) }
    sequence(:public_contacts) { [build(:public_contact)] }
    sequence(:catalogue) { create(:catalogue) }
    sequence(:service_categories) { create_list(:service_category, 2) }
    sequence(:pid) { |_n| "#{catalogue.pid}.#{resource_organisation.pid}.#{abbreviation}" }

    upstream { nil }

    after(:create) { |service, _evaluator| service.reindex(refresh: true) }
    factory :external_service do
      sequence(:order_type) { :order_required }
      sequence(:order_url) { "http://order.com" }
    end
    factory :service_with_offers do
      sequence(:offers) { create_list(:offer_with_parameters, 2) }
    end
  end
end
