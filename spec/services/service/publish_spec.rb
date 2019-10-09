# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Publish do
  it "publish service" do
    service = create(:service)

    described_class.new(service).call

    expect(service.reload).to be_published
  end

  it "publish unverified service" do
    service = create(:service)

    described_class.new(service, verified: false).call

    expect(service.reload).to be_unverified
  end
end
