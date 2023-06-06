# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion::Create, backend: true do
  it "creates service opinion" do
    service = create(:service)
    offer = create(:offer, service: service)
    project_item = create(:project_item, offer: offer)

    expect(service.service_opinion_count).to eq(0)
    create(:service_opinion, project_item: project_item, service_rating: "3", order_rating: "3")
    expect(service.service_opinion_count).to eq(1)
  end
end
