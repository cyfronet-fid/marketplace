# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:name) { |n| "service #{n}" }
    sequence(:description) { |n| "service #{n} description" }
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
      sequence(:resource_type) { "DataSource" }
      sequence(:version_control) { false }
      research_product_types { [] }
    end
    sequence(:webpage_url) { "https://wabpage.url" }
    sequence(:terms_of_use_url) { "https://terms.of.use.url" }
    sequence(:access_policies_url) { "https://access.policies.url" }
    publishing_date { Date.current }
    resource_type { "Service" }
    public_contact_emails { ["contact@example.org"] }
    urls { [] }

    sequence(:scientific_domains) { |_n| [create(:scientific_domain)] }
    sequence(:resource_organisation) { |_n| create(:provider) }
    sequence(:providers) { |_n| [create(:provider)] }
    sequence(:categories) { |_n| [create(:category)] }
    sequence(:status) { :published }
    sequence(:trls) { [create(:trl)] }
    sequence(:synchronized_at) { Time.now - 2.days }
    sequence(:catalogue) { create(:catalogue) }
    sequence(:pid) { |n| "#{catalogue.pid}.#{resource_organisation.pid}.service-#{n}" }

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
