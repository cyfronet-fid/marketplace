# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion::UpdateService, backend: true do
  it "initializes service with rating and opinion_count eq zero not nil" do
    service = create(:service)
    expect(service.rating).to eq(0)
    expect(service.service_opinion_count).to eq(0)
  end

  it "updates service rating and service_opinion_count" do
    service = create(:service)
    expect(service.rating).to eq(0)
    expect(service.service_opinion_count).to eq(0)

    project_item = create(:project_item, offer: create(:offer, service: service))
    create(:service_opinion, project_item: project_item, service_rating: "3", order_rating: "3")

    expect(service.rating).to eq(3)
    expect(service.service_opinion_count).to eq(1)
  end

  context "with a Service whose counters have drifted" do
    let(:service) { create(:service, service_opinion_count: 7, rating: 1.0) }

    before do
      offer = create(:offer, service:)
      create(:service_opinion, project_item: create(:project_item, offer:), service_rating: 4)
      create(:service_opinion, project_item: create(:project_item, offer:), service_rating: 5)
    end

    it "counts and averages its Opinions from the rows" do
      expect([service.reload.service_opinion_count, service.rating]).to eq([2, 4.5])
    end
  end

  context "with a Service that fails its validations" do
    let(:service) { create(:service) }

    before do
      service.update_columns(webpage_url: "not a url") # rubocop:disable Rails/SkipsModelValidations
      create(:service_opinion, project_item: create(:project_item, offer: create(:offer, service:)), service_rating: 4)
    end

    it "still updates its counters" do
      expect([service.reload.service_opinion_count, service.rating]).to eq([1, 4])
    end
  end

  context "with an Opinion on a bundled Project item" do
    let(:service) { create(:service) }
    let(:bundle) { create(:bundle, offers: [create(:offer, service:)]) }

    before { create(:service_opinion, project_item: create(:project_item, offer: bundle.offers.first, bundle:)) }

    it "counts it toward the Service of the Project item's own Offer, not the Bundle's" do
      expect([service.reload.service_opinion_count, bundle.service.reload.service_opinion_count]).to eq([1, 0])
    end
  end
end
