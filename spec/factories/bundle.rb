# frozen_string_literal: true

FactoryBot.define do
  factory :bundle do
    sequence(:iid) { |n| n }
    sequence(:name) { |n| "bundle #{n}" }
    sequence(:description) { |n| "Bundle #{n} description" }
    sequence(:bundle_goals) { |_n| [create(:bundle_goal)] }
    sequence(:capabilities_of_goals) { |_n| [create(:bundle_capability_of_goal)] }
    sequence(:contact_email) { |n| "contact#{n}@email.com" }
    sequence(:related_training) { true }
    sequence(:related_training_url) { |n| "https://related#{n}.training.com" }
    sequence(:order_type) { :order_required }
    sequence(:status) { :published }
    sequence(:target_users) { |_n| [create(:target_user)] }
    sequence(:main_offer) { |_n| create(:offer) }
    sequence(:service) { |_n| main_offer.service }
    sequence(:resource_organisation) { |_n| service.resource_organisation }
    sequence(:research_activities) { |_n| [create(:research_activity)] }
    sequence(:offers) { |_n| [create(:offer)] }
    sequence(:scientific_domains) { |_n| [create(:child_scientific_domain)] }
    sequence(:helpdesk_url) { |n| "https://example#{n}.com" }
  end
end
