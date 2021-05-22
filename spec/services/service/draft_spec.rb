# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Draft do
  it "draft service" do
    service = create(:service)
    offer = create(:offer, service: service)
    service.reload
    described_class.new(service).call

    expect(service.reload).to be_draft
    expect(offer.reload).to_not be_draft
  end
end
