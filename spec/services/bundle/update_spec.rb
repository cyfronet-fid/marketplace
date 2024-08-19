# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bundle::Update, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if bundle invalid" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer = create(:open_access_offer, service: build(:open_access_service, resource_organisation: provider2))
      bundle = build(:bundle, main_offer: bundle_offer, research_activities: [])

      expect { described_class.call(bundle, { offers: [bundled_offer] }.stringify_keys) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "doesn't send notification if bundled offer is from the same provider" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider))
      bundle = build(:bundle, main_offer: bundle_offer, offers: [])

      expect { described_class.call(bundle, { offers: [bundled_offer] }.stringify_keys) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "doesn't send notification for offers added previously" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      provider3 = build(:provider)
      bundled_offer1 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer2 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer3 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer4 = create(:offer, service: build(:service, resource_organisation: provider2))
      bundled_offer5 = create(:offer, service: build(:service, resource_organisation: provider3))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider2))
      bundle = build(:bundle, main_offer: bundle_offer, offers: [bundled_offer1])

      expect do
        described_class.call(
          bundle,
          { offers: [bundled_offer1, bundled_offer2, bundled_offer3, bundled_offer4, bundled_offer5] }
        )
      end.to change { ActionMailer::Base.deliveries.count }.by(3)
    end

    it "send notification for added and removed offer" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      provider3 = build(:provider)
      bundled_offer1 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer2 = create(:offer, service: build(:service, resource_organisation: provider3))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider2))
      bundle = build(:bundle, main_offer: bundle_offer, offers: [bundled_offer1])

      expect { described_class.call(bundle, { offers: [bundled_offer2] }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(2)
    end
  end
end
