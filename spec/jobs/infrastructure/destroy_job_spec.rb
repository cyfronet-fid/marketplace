# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::DestroyJob, type: :job do
  let(:provider) { create(:provider) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
  let(:service_category) { create(:service_category) }
  let(:offer) { create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category) }
  let(:project) { create(:project) }
  let(:project_item) { create(:project_item, offer: offer, project: project) }

  let(:infrastructure) do
    Infrastructure.create!(
      project_item: project_item,
      im_base_url: "https://deploy.sandbox.eosc-beyond.eu",
      cloud_site: "IISAS-FedCloud",
      state: "running",
      im_infrastructure_id: "infra-123"
    )
  end

  let(:im_client) { instance_double(InfrastructureManager::Client) }

  before { allow(InfrastructureManager::Client).to receive(:new).and_return(im_client) }

  describe "#perform" do
    context "when destroy succeeds" do
      before { allow(im_client).to receive(:destroy_infrastructure).and_return({ success: true }) }

      it "marks infrastructure as destroyed" do
        described_class.perform_now(infrastructure.id)

        expect(infrastructure.reload.state).to eq("destroyed")
      end

      it "updates project_item status to closed" do
        described_class.perform_now(infrastructure.id)

        project_item.reload
        expect(project_item.status).to eq("Infrastructure has been destroyed")
        expect(project_item.status_type).to eq("closed")
      end

      it "logs success message" do
        expect(Rails.logger).to receive(:info).with(/Destroying Infrastructure/)
        expect(Rails.logger).to receive(:info).with(/destroyed successfully/)

        described_class.perform_now(infrastructure.id)
      end
    end

    context "when destroy fails" do
      before do
        allow(im_client).to receive(:destroy_infrastructure).and_return({ success: false, error: "Permission denied" })
      end

      it "marks infrastructure as failed with error message" do
        described_class.perform_now(infrastructure.id)

        infrastructure.reload
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to include("Permission denied")
      end

      it "updates project_item status to rejected" do
        described_class.perform_now(infrastructure.id)

        project_item.reload
        expect(project_item.status).to include("Failed to destroy")
        expect(project_item.status_type).to eq("rejected")
      end

      it "logs error message" do
        expect(Rails.logger).to receive(:info).with(/Destroying Infrastructure/)
        expect(Rails.logger).to receive(:error).with(/Failed to destroy/)

        described_class.perform_now(infrastructure.id)
      end
    end

    context "when infrastructure cannot be destroyed" do
      it "does nothing if infrastructure not found" do
        expect(im_client).not_to receive(:destroy_infrastructure)
        described_class.perform_now(-1)
      end

      it "does nothing if infrastructure is already destroyed" do
        infrastructure.update_columns(state: "destroyed")

        expect(im_client).not_to receive(:destroy_infrastructure)
        described_class.perform_now(infrastructure.id)
      end

      it "does nothing if infrastructure is pending (no im_infrastructure_id)" do
        infrastructure.update_columns(state: "pending", im_infrastructure_id: nil)

        expect(im_client).not_to receive(:destroy_infrastructure)
        described_class.perform_now(infrastructure.id)
      end
    end

    context "when exception occurs" do
      it "marks infrastructure as failed with exception message" do
        allow(im_client).to receive(:destroy_infrastructure).and_raise(StandardError, "Network error")

        expect(Rails.logger).to receive(:info).with(/Destroying Infrastructure/)
        expect(Rails.logger).to receive(:error).with(/Destroy job failed/)

        described_class.perform_now(infrastructure.id)

        infrastructure.reload
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to eq("Network error")
      end
    end
  end

  describe "destroyable states" do
    %w[creating configured running failed].each do |state_name|
      it "destroys infrastructure in '#{state_name}' state" do
        infrastructure.update_columns(state: state_name)
        allow(im_client).to receive(:destroy_infrastructure).and_return({ success: true })

        described_class.perform_now(infrastructure.id)

        expect(infrastructure.reload.state).to eq("destroyed")
      end
    end
  end

  describe "job configuration" do
    it "uses the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
