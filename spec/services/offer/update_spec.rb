# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Update do
  context "#bundled_offers" do
    it "doesn't send notification if offer invalid" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer = create(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer_to_be =
        create(:open_access_offer, service: build(:open_access_service, resource_organisation: provider2))

      expect { Offer::Update.call(bundle_offer_to_be, { bundled_connected_offers: [bundled_offer] }) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "doesn't send notification if bundled offers removed" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer =
        create(
          :offer,
          service: build(:service, resource_organisation: provider2),
          bundled_connected_offers: [bundled_offer]
        )

      expect { Offer::Update.call(bundle_offer, { bundled_connected_offers: [] }) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "doesn't send notification if offer non-public" do
      bundled_offer = create(:offer, service: build(:service))
      bundle_offer = create(:offer, service: build(:service, status: "draft"))

      expect { Offer::Update.call(bundle_offer, { bundled_connected_offers: [bundled_offer] }) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "sends notification if bundled offers updated" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer1 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer2 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer3 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer =
        create(
          :offer,
          service: build(:service, resource_organisation: provider2),
          bundled_connected_offers: [bundled_offer1, bundled_offer2]
        )

      _bundle =
        create(
          :bundle,
          service: bundle_offer.service,
          main_offer: bundle_offer,
          offers: bundle_offer.bundled_connected_offers
        )

      expect do
        Offer::Update.call(bundle_offer, { bundled_connected_offers: [bundled_offer1, bundled_offer3] })
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer =
        create(
          :offer,
          service: build(:service, resource_organisation: provider),
          bundled_connected_offers: [bundled_offer]
        )

      expect { Offer::Update.call(bundled_offer, { internal: false }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)

      bundle_offer.reload
      expect(bundle_offer.bundled_connected_offers).to be_blank
    end
  end
end
