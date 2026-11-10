# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PcDelete::Cascading, :backend do
  let(:service) { create(:service) }

  context "when a registry source matches" do
    before do
      create(:service_source, source_type: :eosc_registry, service: service, eid: service.id)
      described_class.call(service.id)
    end

    it "sets deleted status for the service" do
      expect(service.reload.status).to eq("deleted")
    end
  end

  context "when no registry source matches" do
    before { described_class.call(service.id) }

    it "leaves the service unchanged" do
      expect(service.reload.status).to eq("published")
    end
  end
end
