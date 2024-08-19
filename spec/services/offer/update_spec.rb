# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Update, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if offer non-public" do
      bundled_offer = create(:offer, service: build(:service))
      bundle = create(:bundle, status: "draft", service: build(:service, status: "draft"))

      expect { Bundle::Update.call(bundle, { offers: [bundled_offer] }) }.not_to change {
        ActionMailer::Base.deliveries.count
      }
    end

    it "sends notification if bundled offers updated" do
      provider1 = build(:provider)
      provider2 = build(:provider)
      bundled_offer1 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer2 = build(:offer, service: build(:service, resource_organisation: provider1))
      bundled_offer3 = create(:offer, service: build(:service, resource_organisation: provider1))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider2))

      bundle = create(:bundle, main_offer: bundle_offer, offers: [bundled_offer1, bundled_offer2])

      # ActionMailer should send one mail to bundled and one to unbundled offer.
      expect { Bundle::Update.call(bundle, { offers: [bundled_offer1, bundled_offer3] }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(2)
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer = build(:offer, service: build(:service, resource_organisation: provider))

      bundle = create(:bundle, main_offer: bundle_offer, offers: [bundled_offer])

      expect { Offer::Update.call(bundled_offer, { status: "draft" }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)

      bundled_offer.reload
      bundle.reload

      expect(bundle).to be_draft
    end
  end
end
