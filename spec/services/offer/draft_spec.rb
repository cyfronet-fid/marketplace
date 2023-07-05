# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Draft, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if no bundle offers" do
      drafted_offer = create(:offer)

      expect { described_class.call(drafted_offer) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = create(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider))
      bundle = create(:bundle, service: bundle_offer.service, main_offer: bundle_offer, offer_ids: [bundled_offer.id])

      expect { described_class.call(bundled_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      bundled_offer.reload
      bundle.reload

      expect(bundle.valid?).to be_falsey
      expect(bundle.status).to eq("draft")
    end
  end
end
