# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Unpublish, :backend do
  it "draft service" do
    service = create(:service)
    offer = create(:offer, service: service)
    service.reload
    described_class.call(service)

    expect(service.reload).to be_unpublished
    expect(offer.reload).not_to be_unpublished
  end

  describe "#bundled_offers" do
    it "sends notification and unbundles" do
      service = build(:service)
      bundled_offer = create(:offer, service: service)
      bundle_offer = create(:offer)
      bundle = create(:bundle, main_offer: bundle_offer, offers: [bundled_offer])
      service.reload
      expect { described_class.call(service) }.to have_enqueued_mail(OfferMailer, :offer_unbundled)

      bundle.reload
      expect(bundle).to be_draft
    end
  end
end
