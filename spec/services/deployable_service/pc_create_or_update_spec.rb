# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::PcCreateOrUpdate, backend: true do
  let(:provider_eid) { "test.provider" }
  let!(:provider) { create(:provider, name: "Test Provider") }
  let!(:provider_source) do
    create(:provider_source, source_type: "eosc_registry", eid: provider_eid, provider: provider)
  end

  describe "#call" do
    context "when creating a new deployable service" do
      let(:jms_deployable_service) { build(:jms_deployable_service, provider_eid: provider_eid) }

      it "creates a deployable service with a source" do
        expect { described_class.new(jms_deployable_service, true).call }.to change(DeployableService, :count).by(
          1
        ).and change(DeployableServiceSource, :count).by(1)
      end

      it "sets the upstream_id on the deployable service" do
        result = described_class.new(jms_deployable_service, true).call

        expect(result.upstream_id).to be_present
        expect(result.sources.first).to be_present
        expect(result.sources.first.eid).to eq(jms_deployable_service["id"])
      end

      it "sets the source_type to eosc_registry" do
        result = described_class.new(jms_deployable_service, true).call

        expect(result.sources.first.source_type).to eq("eosc_registry")
      end
    end

    context "when updating an existing deployable service" do
      let!(:existing_ds) { create(:deployable_service, pid: "deployable.service.1", name: "Old Name") }
      let!(:existing_source) do
        create(:deployable_service_source, deployable_service: existing_ds, eid: "deployable.service.1")
      end
      let(:jms_deployable_service) do
        build(:jms_deployable_service, eid: "deployable.service.1", name: "New Name", provider_eid: provider_eid)
      end

      before { existing_ds.update!(upstream_id: existing_source.id) }

      it "updates the existing deployable service" do
        expect { described_class.new(jms_deployable_service, true).call }.not_to change(DeployableService, :count)

        existing_ds.reload
        expect(existing_ds.name).to eq("New Name")
      end

      it "does not create a new source" do
        expect { described_class.new(jms_deployable_service, true).call }.not_to change(DeployableServiceSource, :count)
      end
    end

    context "when deployable service is inactive" do
      let(:jms_deployable_service) { build(:jms_deployable_service, provider_eid: provider_eid) }

      it "creates with draft status" do
        result = described_class.new(jms_deployable_service, false).call

        expect(result.status).to eq("draft")
      end
    end
  end
end
