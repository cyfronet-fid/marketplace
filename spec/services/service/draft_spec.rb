# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Draft do
  it "draft service" do
    service = create(:service)
    offer = create(:offer, service: service)
    service.reload
    described_class.call(service)

    expect(service.reload).to be_draft
    expect(offer.reload).to_not be_draft
  end

  context "#bundled_offers" do
    it "sends notification and unbundles" do
      service = build(:service)
      bundled_offer = build(:offer, service: service)
      bundle_offer = create(:offer, bundled_connected_offers: [bundled_offer])

      expect { described_class.call(service) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      bundle_offer.reload
      expect(bundle_offer).not_to be_bundle
    end
  end
end
