# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Publish do
  it "removes service from db" do
    service = create(:service)

    described_class.new(service).call

    expect(service.reload).to be_published
  end
end
