# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Update do
  it "updates attributes" do
    service = create(:service)

    described_class.new(service, name: "new name").call

    expect(service.name).to eq("new name")
  end

  it "updates attributes of default offer if it exists" do
    service = create(:service, offers: [create(:offer)])
    offer = service.offers.first

    described_class.new(service, name: "new name",
                                 order_url: "http://order.valid",
                                 order_type: "fully_open_access").call

    expect(service.offers.size).to eq(1)

    expect(offer.order_type).to eq("fully_open_access")
    expect(offer.order_url).to eq("http://order.valid")
    expect(offer.status).to eq("published")
  end

  it "creates new offer by service update if offers_count equals 0" do
    service = create(:service, order_type: "fully_open_access")

    expect(service.offers.size).to eq(0)

    described_class.new(service, name: "new name",
                                 order_url: "http://order.valid",
                                 order_type: "fully_open_access").call

    service.reload

    expect(service.offers.size).to eq(1)

    offer = service.offers.first

    expect(offer.order_type).to eq("fully_open_access")
    expect(offer.order_url).to eq("http://order.valid")
    expect(offer.status).to eq("published")
  end
end
