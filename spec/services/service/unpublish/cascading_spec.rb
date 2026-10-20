# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Unpublish::Cascading, :backend do
  let(:service) { create(:service) }

  before do
    service.name = ""
    described_class.call(service)
  end

  it "unpublishes a service that fails validation" do
    expect(service.reload.status).to eq("unpublished")
  end
end
