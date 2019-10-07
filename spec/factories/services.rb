# frozen_string_literal: true

FactoryBot.define do
  factory :service do
    sequence(:title) { |n| "service #{n}" }
    sequence(:description) { |n| "service #{n} description" }
    sequence(:tagline) { |n| "service #{n} tagline" }
    sequence(:service_type) { :orderable }

    factory :open_access_service do
      sequence(:connected_url) { "https://sample.url" }
      sequence(:service_type) { :open_access }
    end
    sequence(:webpage_url) { "https://wabpage.url"  }
    sequence(:manual_url) { "https://manual.url"  }
    sequence(:helpdesk_url) { "https://helpdesk.url"  }
    sequence(:tutorial_url) { "https://tutorial.url"  }
    sequence(:terms_of_use_url) { "https://terms.of.use.url"  }
    sequence(:sla_url) { "https://corporate.sla.url"  }
    sequence(:access_policies_url) { "https://access.policies.url"  }

    sequence(:places) { |n| "service #{n} place" }
    sequence(:languages) { |n| "service #{n} lanuage" }
    sequence(:dedicated_for) { |n| ["service #{n} dedicated for"] }
    sequence(:restrictions) { |n| "service #{n} restrictions" }
    sequence(:phase) { :alpha }
    sequence(:research_areas) { |n| [create(:research_area, parent: create(:research_area))] }
    sequence(:providers) { |n| [create(:provider)] }
    sequence(:categories) { |n| [create(:category)] }
    sequence(:status) { :published }

    upstream { nil }

    after(:create) do |service, _evaluator|
      service.reindex(refresh: true)
    end
    factory :external_service do
      sequence(:service_type) { :external }
      sequence(:connected_url) { "https://sample.url" }
    end
  end
end
