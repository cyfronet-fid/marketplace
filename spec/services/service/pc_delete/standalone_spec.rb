# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PcDelete::Standalone, :backend do
  subject(:result) { described_class.new(service.id).call }

  let(:service) { create(:service) }

  context "when a registry source matches" do
    before { create(:service_source, source_type: :eosc_registry, service: service, eid: service.id) }

    it "sets deleted status for the service" do
      expect(result.status).to eq("deleted")
    end
  end

  context "when no registry source matches" do
    it "returns nil" do
      expect(result).to be_nil
    end
  end
end
