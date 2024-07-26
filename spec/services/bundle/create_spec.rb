# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bundle::Create, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if offer invalid" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer = build(:open_access_offer, service: build(:open_access_service, resource_organisation: provider2))
      bundle = build(:bundle, main_offer: bundle_offer, offers: [bundled_offer], research_activities: [])

      expect { Bundle::Create.call(bundle) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "doesn't send notification if offer create" do
      offer = build(:offer)

      expect { Offer::Create.call(offer) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "doesn't send notification if bundled offer is from the same provider" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle = build(:bundle, main_offer: bundle_offer, offers: [bundled_offer])

      expect { Bundle::Create.call(bundle) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends notification for bundled offers from different providers" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      provider3 = build(:provider)
      bundled_offer1 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer2 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer3 = build(:offer, service: build(:service, resource_organisation: provider2))
      bundled_offer4 = build(:offer, service: build(:service, resource_organisation: provider3))
      bundle_offer = build(:offer, service: build(:service, resource_organisation: provider2))
      bundle =
        build(
          :bundle,
          main_offer: bundle_offer,
          offers: [bundled_offer1, bundled_offer2, bundled_offer3, bundled_offer4]
        )

      expect { Bundle::Create.call(bundle) }.to change { ActionMailer::Base.deliveries.count }.by(3)
    end
  end
end
