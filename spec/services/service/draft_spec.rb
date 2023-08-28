# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Draft, backend: true do
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
      bundle_offer = create(:offer)
      bundle = create(:bundle, main_offer: bundle_offer, offers: [bundled_offer])
      expect { described_class.call(service) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      bundle.reload
      expect(bundle.status).to eq("draft")
    end
  end
end
