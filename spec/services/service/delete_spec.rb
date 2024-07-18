# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Delete, backend: true do
  it "Set delete status for service" do
    service = create(:service)

    described_class.call(service)
    service.reload
    expect(service.status).to eq("deleted")
  end
end
