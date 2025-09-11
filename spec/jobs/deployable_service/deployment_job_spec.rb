# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::DeploymentJob, type: :job do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:provider) { create(:provider) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
  let(:service_category) { create(:service_category) }
  let(:offer) { create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category) }
  let(:project_item) { create(:project_item, project: project, offer: offer, status: "created", status_type: :created) }

  subject { described_class.new }

  describe "#perform" do
    context "when deployment is successful" do
      let(:filled_template) { "filled tosca template content" }
      let(:deployment_url) { "https://test.jupyter.example.com/jupyterhub/" }
      let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
      let(:successful_im_response) { { success: true, data: "inf-12345" } }

      before do
        # Mock template filling
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_return(filled_template)

        # Mock Infrastructure Manager API
        allow(InfrastructureManager::Client).to receive(:new).and_return(mock_im_client)
        allow(mock_im_client).to receive(:create_infrastructure).and_return(successful_im_response)

        # Mock parameter extraction and URL construction
        allow(subject).to receive(:extract_user_parameters).and_return(
          { "kube_public_dns_name" => "test.jupyter.example.com" }
        )
        allow(subject).to receive(:current_user_token).and_return("test_token")
        allow(subject).to receive(:store_infrastructure_metadata)

        # Mock logging
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
      end

      it "calls ToscaTemplateFiller to get filled template" do
        subject.perform(project_item)

        expect(DeployableService::ToscaTemplateFiller).to have_received(:call).with(project_item)
      end

      it "calls Infrastructure Manager API with filled template" do
        subject.perform(project_item)

        expect(InfrastructureManager::Client).to have_received(:new).with("test_token")
        expect(mock_im_client).to have_received(:create_infrastructure).with(filled_template)
      end

      it "updates project item status to ready with deployment message and link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status).to eq("Deployment ready at #{deployment_url}")
        expect(project_item.status_type).to eq("ready")
        expect(project_item.deployment_link).to eq(deployment_url)
      end

      it "logs deployment information" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:info).with(/Deploying TOSCA template to Infrastructure Manager/)
        expect(Rails.logger).to have_received(:debug).with(/Filled TOSCA Template:/)
      end
    end

    context "when deployment fails due to IM API failure" do
      let(:filled_template) { "filled tosca template content" }
      let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
      let(:failed_im_response) { { success: false, error: "Authentication failed" } }

      before do
        # Mock successful template filling
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_return(filled_template)

        # Mock failed Infrastructure Manager API
        allow(InfrastructureManager::Client).to receive(:new).and_return(mock_im_client)
        allow(mock_im_client).to receive(:create_infrastructure).and_return(failed_im_response)

        allow(subject).to receive(:current_user_token).and_return("test_token")
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:error)
      end

      it "updates project item status to failed" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status).to eq("Deployment failed - please contact support")
        expect(project_item.status_type).to eq("rejected")
      end

      it "logs the IM API error" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:error).with("Failed to create infrastructure: Authentication failed")
      end

      it "does not update deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to be_nil
      end
    end

    context "when an exception occurs" do
      before do
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_raise(
          StandardError.new("Template processing error")
        )
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:error).with("Deployment job failed: Template processing error")
      end

      it "updates project item status to failed" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status).to eq("Deployment failed - please contact support")
        expect(project_item.status_type).to eq("rejected")
      end

      it "does not update deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to be_nil
      end
    end

    describe "job queue configuration" do
      it "is queued on default queue" do
        expect(described_class.queue_name).to eq("default")
      end
    end

    describe "integration with ActiveJob" do
      it "can be enqueued" do
        expect { described_class.perform_later(project_item) }.to have_enqueued_job(described_class).with(
          project_item
        ).on_queue("default")
      end
    end
  end

  describe "private methods" do
    describe "#deploy_to_infrastructure_manager" do
      let(:filled_template) { "mock filled template" }
      let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
      let(:successful_im_response) { { success: true, data: "inf-12345" } }

      before do
        allow(InfrastructureManager::Client).to receive(:new).and_return(mock_im_client)
        allow(subject).to receive(:current_user_token).and_return("test_token")
        allow(subject).to receive(:extract_user_parameters).and_return(
          { "kube_public_dns_name" => "custom.domain.com" }
        )
        allow(subject).to receive(:store_infrastructure_metadata)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:error)
      end

      it "calls IM API and returns deployment URL on success" do
        allow(mock_im_client).to receive(:create_infrastructure).and_return(successful_im_response)

        result = subject.send(:deploy_to_infrastructure_manager, project_item, filled_template)

        expect(InfrastructureManager::Client).to have_received(:new).with("test_token")
        expect(mock_im_client).to have_received(:create_infrastructure).with(filled_template)
        expect(result).to eq("https://custom.domain.com/jupyterhub/")
      end

      it "returns nil on IM API failure" do
        failed_response = { success: false, error: "API Error" }
        allow(mock_im_client).to receive(:create_infrastructure).and_return(failed_response)

        result = subject.send(:deploy_to_infrastructure_manager, project_item, filled_template)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with("Failed to create infrastructure: API Error")
      end

      it "uses fallback DNS name when parameter not provided" do
        allow(subject).to receive(:extract_user_parameters).and_return({})
        allow(mock_im_client).to receive(:create_infrastructure).and_return(successful_im_response)

        result = subject.send(:deploy_to_infrastructure_manager, project_item, filled_template)

        expect(result).to eq("https://jupytermount.vm.fedcloud.eu/jupyterhub/")
      end
    end

    describe "#extract_user_parameters" do
      it "extracts parameters from JSON array format" do
        properties = ['{"id": "param1", "value": "value1"}', '{"id": "param2", "value": "value2"}']

        result = subject.send(:extract_user_parameters, properties)

        expect(result).to eq({ "param1" => "value1", "param2" => "value2" })
      end

      it "extracts parameters from hash format" do
        properties = { "param1" => "value1", "param2" => "value2" }

        result = subject.send(:extract_user_parameters, properties)

        expect(result).to eq({ "param1" => "value1", "param2" => "value2" })
      end
    end

    describe "#current_user_token" do
      context "when user has authentication_token" do
        before { user.update!(authentication_token: "user_specific_token") }

        it "returns user authentication token" do
          result = subject.send(:current_user_token, project_item)
          expect(result).to eq("user_specific_token")
        end
      end

      context "when user has no authentication_token" do
        before do
          user.update_column(:authentication_token, nil) # Use update_column to bypass callbacks
        end

        it "returns demo token from environment" do
          stub_const("ENV", ENV.to_hash.merge("IM_DEMO_TOKEN" => "env_demo_token"))

          result = subject.send(:current_user_token, project_item)
          expect(result).to eq("env_demo_token")
        end
      end
    end
  end
end
