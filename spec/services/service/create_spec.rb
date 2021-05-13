# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Create do
  let(:user) { create(:user) }

  it "saves valid service in db" do
    service = described_class.new(build(:service)).call

    expect(service).to be_persisted
  end

  it "saves valid offer in the db" do
    service = described_class.new(build(:service)).call

    expect(service.offers.size).to eq(1)

    offer = service.offers.first

    expect(offer.name).to eq("Offer")
    expect(offer.description).to eq("#{service.name} Offer")
    expect(offer.order_type).to eq(service.order_type)
    expect(offer.order_url).to eq(service.order_url)
    expect(offer.status).to eq("published")
  end
end
