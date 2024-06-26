# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Destroy, backend: true do
  it "changes service status to deleted in the db" do
    service = create(:service)

    described_class.new(service).call

    expect(Service.find_by(id: service.id)&.status).to eq("deleted")
  end
end
