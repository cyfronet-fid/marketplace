# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Delete do
  it "Set delete status for service" do
    service = create(:service)
    create(:service_source,
           source_type: :eic,
           service: service,
           eid: service.id)

    service = described_class.new(service.id).call
    expect(service.status).to eq("deleted")
  end

  it "Does nothing if service not exist" do
    service = create(:service)
    service = described_class.new(service.id).call
    expect(service).to be_nil
  end
end
