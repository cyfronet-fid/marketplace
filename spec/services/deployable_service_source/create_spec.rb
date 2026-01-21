# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableServiceSource::Create, backend: true do
  describe "#call" do
    let(:deployable_service) { create(:deployable_service, pid: "test.deployable.service") }

    it "creates a source for the deployable service" do
      expect { described_class.new(deployable_service).call }.to change(DeployableServiceSource, :count).by(1)
    end

    it "sets the eid from the deployable service pid" do
      described_class.new(deployable_service).call

      source = deployable_service.sources.first
      expect(source.eid).to eq("test.deployable.service")
    end

    it "sets the source_type to eosc_registry by default" do
      described_class.new(deployable_service).call

      source = deployable_service.sources.first
      expect(source.source_type).to eq("eosc_registry")
    end

    it "sets the upstream_id on the deployable service" do
      described_class.new(deployable_service).call

      deployable_service.reload
      expect(deployable_service.upstream_id).to eq(deployable_service.sources.first.id)
    end
  end
end
