# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Suspend::Cascading, :backend do
  let(:service) { create(:service) }

  before do
    service.name = ""
    described_class.call(service)
  end

  it "suspends a service that fails validation" do
    expect(service.reload.status).to eq("suspended")
  end
end
