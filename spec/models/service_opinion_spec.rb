# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion, type: :model do
  it { should validate_presence_of(:rating) }
  it { should validate_numericality_of(:rating) }
  it { should belong_to(:order) }

  it "#update_service_rating" do
    service = create(:service)
    expect(service.rating).to eq(0.0)

    create(:service_opinion, order: create(:order, service: service), rating: "3")

    expect(service.rating).to eq(3.0)
  end
end
