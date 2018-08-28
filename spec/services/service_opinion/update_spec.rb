# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion::UpdateService do
  it "initializes service with rating and opinion_count eq zero not nil" do
    service = create(:service)
    expect(service.rating).to eq(0)
    expect(service.service_opinion_count).to eq(0)
  end

  it "updates service rating and service_opinion_count" do
    service = create(:service)
    expect(service.rating).to eq(0)
    expect(service.service_opinion_count).to eq(0)

    order = create(:order, service: service)
    create(:service_opinion, order: order, rating: "3")

    expect(service.rating).to eq(3)
    expect(service.service_opinion_count).to eq(1)
  end
end
