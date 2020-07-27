# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:name) { |n| "service #{n}" }
    sequence(:description) { |n| "service #{n} description" }
    sequence(:tagline) { |n| "service #{n} tagline" }
    sequence(:order_type) { :orderable }

    factory :open_access_service do
      sequence(:order_type) { :open_access }
    end
    sequence(:webpage_url) { "https://wabpage.url"  }
    sequence(:manual_url) { "https://manual.url"  }
    sequence(:helpdesk_url) { "https://helpdesk.url"  }
    sequence(:training_information_url) { "https://tutorial.url"  }
    sequence(:terms_of_use_url) { "https://terms.of.use.url"  }
    sequence(:sla_url) { "https://corporate.sla.url"  }
    sequence(:access_policies_url) { "https://access.policies.url"  }

    sequence(:language_availability) { [I18nData.languages.values.sample] }
    sequence(:geographical_availabilities) { |n| ["EU"] }
    sequence(:dedicated_for) { |n| ["service #{n} dedicated for"] }
    sequence(:restrictions) { |n| "service #{n} restrictions" }
    sequence(:scientific_domains) { |n| [create(:scientific_domain)] }
    sequence(:resource_organisation) { |n| create(:provider) }
    sequence(:providers) { |n| [create(:provider)] }
    sequence(:categories) { |n| [create(:category)] }
    sequence(:status) { :published }
    sequence(:version) { nil }
    sequence(:trl) { [create(:trl)] }
    sequence(:last_update) { Time.now - 2.days }

    upstream { nil }

    after(:create) do |service, _evaluator|
      service.reindex(refresh: true)
    end
    factory :external_service do
      sequence(:order_type) { :external }
    end
  end
end
