# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Draft do
  context "#bundled_offers" do
    it "doesn't send notification if no bundle offers" do
      drafted_offer = create(:offer)

      expect { Offer::Draft.call(drafted_offer) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer =
        create(:offer, service: build(:service, resource_organisation: provider), bundled_offers: [bundled_offer])

      expect { Offer::Draft.call(bundled_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      bundle_offer.reload
      expect(bundle_offer.bundled_offers).to be_blank
    end
  end
end
