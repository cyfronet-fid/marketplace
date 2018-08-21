# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion, type: :model do
  it { should validate_presence_of(:rating) }
  it { should validate_numericality_of(:rating) }
  it { should belong_to(:order) }

  it "has rating" do
    service_opinion = create(:service_opinion, rating: "3")

    expect(service_opinion.rating).to eq(3)
  end

  it "service_opinion updates service.rating" do
    service = create(:service)
    expect(service.rating).to eq(0.0)

    order = create(:order, service: service)

    service_opinion = create(:service_opinion, order: order, rating: "3")
    service_opinion.save

    expect(service.rating).to eq(3.0)
  end

  it "service_opinion sends after_save callback" do
    service_opinion = create(:service_opinion, rating: "3")
    expect(service_opinion).to receive(:update_service_rating)
    service_opinion.save
  end
end
