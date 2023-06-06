# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceOpinion, type: :model, backend: true do
  it { should validate_presence_of(:service_rating) }
  it { should validate_presence_of(:order_rating) }
  it { should validate_numericality_of(:service_rating).with_message("Please rate this question to help other users") }
  it { should validate_numericality_of(:order_rating).with_message("Please rate this question to help other users") }
  it { should belong_to(:project_item) }

  it "#update_service_rating" do
    service = create(:service)
    offer = create(:offer, service: service)

    expect(service.rating).to eq(0.0)

    create(:service_opinion, project_item: create(:project_item, offer: offer), service_rating: "3", order_rating: "3")

    expect(service.rating).to eq(3.0)
  end
end
