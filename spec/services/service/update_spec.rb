# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Update, backend: true do
  it "updates attributes" do
    service = create(:service)

    described_class.call(service, name: "new name")

    expect(service.name).to eq("new name")
  end

  it "updates attributes of default offer if it exists" do
    service = create(:service, offers: [create(:offer)])
    offer = service.offers.first

    described_class.call(service, name: "new name", order_url: "http://order.valid", order_type: "fully_open_access")

    expect(service.offers.size).to eq(1)

    expect(offer.order_type).to eq("fully_open_access")
    expect(offer.order_url).to eq("http://order.valid")
    expect(offer).to be_published
  end

  it "doesn't create new offer by service update if offers_count equals 0" do
    service = create(:service, order_type: "fully_open_access")

    expect(service.offers.size).to eq(0)

    described_class.call(service, name: "new name", order_url: "http://order.valid", order_type: "fully_open_access")

    service.reload

    expect(service.offers.size).to eq(0)
  end

  it "doesn't create a new offer if service update fails" do
    service = create(:service)

    described_class.call(service, order_url: "invalid.url")
    service.reload

    expect(service.offers.size).to eq(0)
  end

  context "#bundled_offers" do
    it "sends notification if service made public" do
      service = build(:service, status: "draft")
      bundled_offer = build(:offer)
      create(:bundle, service: service, offers: [bundled_offer])

      expect { described_class.call(service, { status: "published" }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end

    it "sends notification and unbundles if service made non-public" do
      service = build(:service)
      bundled_offer = create(:offer, service: service)
      bundle_offer = create(:offer)
      bundle = create(:bundle, main_offer: bundle_offer, offers: [bundled_offer])

      service.reload

      expect { described_class.call(service, { status: "draft" }) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)

      bundle.reload
      expect(bundle).to be_draft
    end
  end
end
