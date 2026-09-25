# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Delete, :backend do
  let(:service) { create(:service) }
  let!(:offer) { create(:offer, service: service) }

  before { described_class.call(service.reload) }

  it "sets deleted status for the service" do
    expect(service.reload.status).to eq("deleted")
  end

  it "enqueues deletion of the service's offers" do
    expect(DeleteJob).to have_been_enqueued.with(offer)
  end
end
