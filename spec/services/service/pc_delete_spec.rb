# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PcDelete, backend: true do
  it "Set delete status for service" do
    service = create(:service)
    create(:service_source, source_type: :eosc_registry, service: service, eid: service.id)

    described_class.call(service.id)
    service.reload
    expect(service.status).to eq("deleted")
  end

  it "Does nothing if service not exist" do
    service = create(:service)
    described_class.call(service.id)
    service.reload
    expect(service.status).to eq("published")
  end
end
