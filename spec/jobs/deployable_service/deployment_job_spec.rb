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
      let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
      let(:successful_im_response) do
        { success: true, data: { "uri" => "https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345" } }
      end

      before do
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_return(filled_template)
        allow(InfrastructureManager::Client).to receive(:new).with(nil, "IISAS-FedCloud").and_return(mock_im_client)
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(
          successful_im_response
        )
        allow(Rails.logger).to receive(:info)
      end

      it "calls ToscaTemplateFiller to get filled template" do
        subject.perform(project_item)

        expect(DeployableService::ToscaTemplateFiller).to have_received(:call).with(project_item)
      end

      it "calls Infrastructure Manager API with filled template" do
        subject.perform(project_item)

        expect(InfrastructureManager::Client).to have_received(:new).with(nil, "IISAS-FedCloud")
        expect(mock_im_client).to have_received(:create_infrastructure).with(filled_template)
      end

      it "updates project item status to ready with deployment info" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("ready")
        expect(project_item.status).to include("Deployment ready at")
        expect(project_item.status).to include("inf-12345")
        expect(project_item.deployment_link).to include("inf-12345")
      end

      it "logs deployment information" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:info).with(
          "Starting deployment for ProjectItem #{project_item.id} (#{project_item.offer&.name})"
        )
        expect(Rails.logger).to have_received(:info).with("Deployment successful for ProjectItem #{project_item.id}")
      end
    end

    context "when deployment fails due to IM API failure" do
      let(:filled_template) { "filled tosca template content" }
      let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
      let(:failed_im_response) do
        { success: false, error: "No VMI obtained from Sites to system 'front'", status_code: 400 }
      end

      before do
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_return(filled_template)
        allow(InfrastructureManager::Client).to receive(:new).with(nil, "IISAS-FedCloud").and_return(mock_im_client)
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(failed_im_response)
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)
      end

      it "updates project item status to rejected" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("rejected")
        expect(project_item.status).to include(
          "Deployment failed - Infrastructure Manager did not return a deployment address"
        )
      end

      it "logs the IM API error" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:error).with("Deployment failed for ProjectItem #{project_item.id}")
        expect(Rails.logger).to have_received(:error).with("IM deployment failed: #{failed_im_response[:error]}")
      end

      it "does not update deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to be_nil
      end
    end

    context "when an exception occurs" do
      before do
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).and_raise(StandardError, "Template error")
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:error).with(
          "Deployment job failed for ProjectItem #{project_item.id}: StandardError: Template error"
        )
      end

      it "updates project item status to rejected" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("rejected")
        expect(project_item.status).to include("Deployment failed due to system error: Template error")
      end
    end
  end

  describe "private methods" do
    describe "#extract_deployment_uri" do
      it "extracts URI from hash response" do
        response_data = { "uri" => "https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345" }
        result = subject.send(:extract_deployment_uri, response_data)

        expect(result).to eq("https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345")
      end

      it "extracts URI from string response containing http" do
        response_data = "https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345"
        result = subject.send(:extract_deployment_uri, response_data)

        expect(result).to eq("https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345")
      end

      it "returns nil for non-URI string" do
        response_data = "inf-12345"
        result = subject.send(:extract_deployment_uri, response_data)

        expect(result).to be_nil
      end

      it "returns nil for nil input" do
        result = subject.send(:extract_deployment_uri, nil)

        expect(result).to be_nil
      end
    end
  end
end
