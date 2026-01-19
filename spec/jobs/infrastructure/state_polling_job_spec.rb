# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::StatePollingJob, type: :job do
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
      state: "creating",
      im_infrastructure_id: "infra-123"
    )
  end

  let(:im_client) { instance_double(InfrastructureManager::Client) }

  before { allow(InfrastructureManager::Client).to receive(:new).and_return(im_client) }

  describe "#perform" do
    context "with infrastructure_id argument (single polling)" do
      it "polls the specific infrastructure" do
        allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
        allow(im_client).to receive(:get_outputs).and_return({ success: true, data: { "outputs" => {} } })

        described_class.perform_now(infrastructure.id)

        expect(infrastructure.reload.state).to eq("running")
      end

      it "does nothing if infrastructure not found" do
        expect(im_client).not_to receive(:get_state)
        described_class.perform_now(-1)
      end

      it "does nothing if infrastructure has no im_infrastructure_id" do
        infrastructure.update_columns(im_infrastructure_id: nil)

        expect(im_client).not_to receive(:get_state)
        described_class.perform_now(infrastructure.id)
      end

      it "does nothing if infrastructure is destroyed" do
        infrastructure.update_columns(state: "destroyed")

        expect(im_client).not_to receive(:get_state)
        described_class.perform_now(infrastructure.id)
      end

      it "does nothing if infrastructure is failed" do
        infrastructure.update_columns(state: "failed")

        expect(im_client).not_to receive(:get_state)
        described_class.perform_now(infrastructure.id)
      end
    end

    context "without infrastructure_id argument (poll all pending)" do
      it "polls all pending infrastructures" do
        # Create another project_item for the second infrastructure
        project_item2 = create(:project_item, offer: offer, project: project)
        infra2 =
          Infrastructure.create!(
            project_item: project_item2,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            im_infrastructure_id: "infra-456",
            last_state_check_at: 2.minutes.ago
          )

        # Set infrastructure to also need polling
        infrastructure.update_columns(last_state_check_at: 2.minutes.ago)

        allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
        allow(im_client).to receive(:get_outputs).and_return({ success: true, data: { "outputs" => {} } })

        described_class.perform_now

        expect(infrastructure.reload.state).to eq("running")
        expect(infra2.reload.state).to eq("running")
      end

      it "skips infrastructures without im_infrastructure_id" do
        infrastructure.update_columns(im_infrastructure_id: nil, last_state_check_at: 2.minutes.ago)

        expect(im_client).not_to receive(:get_state)
        described_class.perform_now
      end

      it "continues polling other infrastructures when one fails" do
        project_item2 = create(:project_item, offer: offer, project: project)
        infra2 =
          Infrastructure.create!(
            project_item: project_item2,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            im_infrastructure_id: "infra-456",
            last_state_check_at: 2.minutes.ago
          )
        infrastructure.update_columns(last_state_check_at: 2.minutes.ago)

        # First call raises, second succeeds
        call_count = 0
        allow(im_client).to receive(:get_state) do
          call_count += 1
          if call_count == 1
            raise StandardError, "Connection failed"
          else
            { success: true, data: { "state" => "running" } }
          end
        end
        allow(im_client).to receive(:get_outputs).and_return({ success: true, data: { "outputs" => {} } })

        expect(Rails.logger).to receive(:error).with(/Failed to poll Infrastructure/)

        described_class.perform_now

        # Both should have updated last_state_check_at
        expect(infrastructure.reload.last_state_check_at).to be_present
        expect(infra2.reload.last_state_check_at).to be_present
      end
    end
  end

  describe "state updates" do
    before { infrastructure.update_columns(last_state_check_at: 2.minutes.ago) }

    it "updates state from IM response" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "configured" } })

      described_class.perform_now(infrastructure.id)

      expect(infrastructure.reload.state).to eq("configured")
    end

    it "handles failed state from IM" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "failed" } })

      described_class.perform_now(infrastructure.id)

      expect(infrastructure.reload.state).to eq("failed")
      expect(infrastructure.last_error).to include("failed")
    end

    it "logs warning when get_state fails" do
      allow(im_client).to receive(:get_state).and_return({ success: false, error: "Connection timeout" })

      expect(Rails.logger).to receive(:warn).with(/Could not get state/)

      described_class.perform_now(infrastructure.id)

      # State should remain unchanged
      expect(infrastructure.reload.state).to eq("creating")
    end
  end

  describe "output fetching" do
    before { infrastructure.update_columns(last_state_check_at: 2.minutes.ago) }

    it "fetches outputs when infrastructure is running" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
      allow(im_client).to receive(:get_outputs).and_return(
        { success: true, data: { "outputs" => { "jupyterhub_url" => "https://jupyter.example.com" } } }
      )

      described_class.perform_now(infrastructure.id)

      expect(infrastructure.reload.outputs).to eq({ "jupyterhub_url" => "https://jupyter.example.com" })
    end

    it "skips output fetch if outputs already have jupyterhub_url" do
      infrastructure.update_columns(outputs: { "jupyterhub_url" => "https://existing.com" })
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })

      expect(im_client).not_to receive(:get_outputs)

      described_class.perform_now(infrastructure.id)
    end

    it "updates project_item deployment_link when jupyterhub_url is found" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
      allow(im_client).to receive(:get_outputs).and_return(
        { success: true, data: { "outputs" => { "jupyterhub_url" => "https://jupyter.example.com" } } }
      )

      described_class.perform_now(infrastructure.id)

      expect(project_item.reload.deployment_link).to eq("https://jupyter.example.com")
      expect(project_item.status).to include("Deployment ready")
    end

    it "does not update project_item if deployment_link matches" do
      project_item.update!(deployment_link: "https://jupyter.example.com")
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
      allow(im_client).to receive(:get_outputs).and_return(
        { success: true, data: { "outputs" => { "jupyterhub_url" => "https://jupyter.example.com" } } }
      )

      expect(project_item).not_to receive(:update!)

      described_class.perform_now(infrastructure.id)
    end

    it "handles empty outputs gracefully" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
      allow(im_client).to receive(:get_outputs).and_return({ success: true, data: { "outputs" => {} } })

      described_class.perform_now(infrastructure.id)

      expect(infrastructure.reload.outputs).to eq({})
    end

    it "handles get_outputs failure gracefully" do
      allow(im_client).to receive(:get_state).and_return({ success: true, data: { "state" => "running" } })
      allow(im_client).to receive(:get_outputs).and_return({ success: false, error: "Failed" })

      # Should not raise
      described_class.perform_now(infrastructure.id)

      expect(infrastructure.reload.state).to eq("running")
    end
  end

  describe "job configuration" do
    it "uses the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
