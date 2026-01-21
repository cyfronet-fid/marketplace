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

  let(:filled_template) { "filled tosca template content" }
  let(:mock_im_client) { instance_double(InfrastructureManager::Client) }
  let(:infrastructure_id) { "inf-12345" }
  let(:deployment_uri) { "https://deploy.sandbox.eosc-beyond.eu/infrastructures/#{infrastructure_id}" }

  subject { described_class.new }

  before do
    allow(DeployableService::ToscaTemplateFiller).to receive(:call).with(project_item).and_return(filled_template)
    allow(InfrastructureManager::Client).to receive(:new).and_return(mock_im_client)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe "#perform" do
    context "when deployment is successful with outputs available" do
      let(:successful_im_response) { { success: true, data: { "uri" => deployment_uri } } }
      let(:outputs_response) do
        { success: true, data: { "outputs" => { "jupyterhub_url" => "https://jupyter.example.com" } } }
      end

      before do
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(
          successful_im_response
        )
        allow(mock_im_client).to receive(:get_outputs).with(infrastructure_id).and_return(outputs_response)
      end

      it "creates an Infrastructure record" do
        expect { subject.perform(project_item) }.to change(Infrastructure, :count).by(1)
      end

      it "sets infrastructure to pending then running" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("running")
        expect(infrastructure.im_infrastructure_id).to eq(infrastructure_id)
      end

      it "stores outputs on infrastructure" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.outputs["jupyterhub_url"]).to eq("https://jupyter.example.com")
      end

      it "associates infrastructure with project_item" do
        subject.perform(project_item)

        expect(project_item.reload.infrastructure).to be_present
        expect(project_item.infrastructure.im_infrastructure_id).to eq(infrastructure_id)
      end

      it "calls ToscaTemplateFiller to get filled template" do
        subject.perform(project_item)

        expect(DeployableService::ToscaTemplateFiller).to have_received(:call).with(project_item)
      end

      it "calls Infrastructure Manager API with filled template" do
        subject.perform(project_item)

        expect(mock_im_client).to have_received(:create_infrastructure).with(filled_template)
      end

      it "fetches outputs from Infrastructure Manager" do
        subject.perform(project_item)

        expect(mock_im_client).to have_received(:get_outputs).with(infrastructure_id)
      end

      it "updates project item status to ready with jupyterhub URL" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("ready")
        expect(project_item.status).to include("Deployment ready at")
        expect(project_item.deployment_link).to eq("https://jupyter.example.com")
      end

      it "logs deployment information" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:info).with(
          "Starting deployment for ProjectItem #{project_item.id} (#{project_item.offer&.name})"
        )
        expect(Rails.logger).to have_received(:info).with("Deployment successful for ProjectItem #{project_item.id}")
      end
    end

    context "when deployment is successful but outputs are empty" do
      let(:successful_im_response) { { success: true, data: { "uri" => deployment_uri } } }
      let(:outputs_response) { { success: true, data: { "outputs" => {} } } }

      before do
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(
          successful_im_response
        )
        allow(mock_im_client).to receive(:get_outputs).with(infrastructure_id).and_return(outputs_response)
      end

      it "marks infrastructure as configured (not running, since no usable URL)" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("configured")
      end

      it "uses deployment URI as fallback for deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to eq(deployment_uri)
      end
    end

    context "when get_outputs fails" do
      let(:successful_im_response) { { success: true, data: { "uri" => deployment_uri } } }
      let(:outputs_response) { { success: false, error: "Service unavailable" } }

      before do
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(
          successful_im_response
        )
        allow(mock_im_client).to receive(:get_outputs).with(infrastructure_id).and_return(outputs_response)
      end

      it "marks infrastructure as configured (polling will update later)" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("configured")
      end

      it "uses deployment URI for deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to eq(deployment_uri)
      end
    end

    context "when deployment fails due to IM API failure" do
      let(:failed_im_response) do
        { success: false, error: "No VMI obtained from Sites to system 'front'", status_code: 400 }
      end

      before do
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(failed_im_response)
      end

      it "creates an Infrastructure record" do
        expect { subject.perform(project_item) }.to change(Infrastructure, :count).by(1)
      end

      it "marks infrastructure as failed" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to include("No VMI obtained")
      end

      it "updates project item status to rejected" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("rejected")
        expect(project_item.status).to include("Deployment failed")
      end

      it "logs the IM API error" do
        subject.perform(project_item)

        expect(Rails.logger).to have_received(:error).with(/IM deployment failed/)
      end

      it "does not update deployment_link" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.deployment_link).to be_nil
      end
    end

    context "when IM returns no deployment URI" do
      let(:no_uri_response) { { success: true, data: {} } }

      before do
        allow(mock_im_client).to receive(:create_infrastructure).with(filled_template).and_return(no_uri_response)
      end

      it "marks infrastructure as failed" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to include("No deployment URI")
      end

      it "updates project item status to rejected" do
        subject.perform(project_item)

        project_item.reload
        expect(project_item.status_type).to eq("rejected")
      end
    end

    context "when an exception occurs during template filling" do
      before do
        allow(DeployableService::ToscaTemplateFiller).to receive(:call).and_raise(StandardError, "Template error")
      end

      it "creates an Infrastructure record first" do
        expect { subject.perform(project_item) }.to change(Infrastructure, :count).by(1)
      end

      it "marks infrastructure as failed" do
        subject.perform(project_item)

        infrastructure = Infrastructure.last
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to eq("Template error")
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
        response_data = { "uri" => deployment_uri }
        result = subject.send(:extract_deployment_uri, response_data)

        expect(result).to eq(deployment_uri)
      end

      it "extracts URI from string response containing http" do
        result = subject.send(:extract_deployment_uri, deployment_uri)

        expect(result).to eq(deployment_uri)
      end

      it "returns nil for non-URI string" do
        result = subject.send(:extract_deployment_uri, "inf-12345")

        expect(result).to be_nil
      end

      it "returns nil for nil input" do
        result = subject.send(:extract_deployment_uri, nil)

        expect(result).to be_nil
      end
    end

    describe "#extract_infrastructure_id" do
      it "extracts ID from standard IM URI" do
        uri = "https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345"
        result = subject.send(:extract_infrastructure_id, uri)

        expect(result).to eq("inf-12345")
      end

      it "extracts ID from URI with im-dev prefix" do
        uri = "https://deploy.sandbox.eosc-beyond.eu/im-dev/infrastructures/abc-789"
        result = subject.send(:extract_infrastructure_id, uri)

        expect(result).to eq("abc-789")
      end

      it "extracts UUID-style ID" do
        uuid = "cc2f148a-9f5e-11f0-9a72-2b7a5255cf3a"
        uri = "https://deploy.sandbox.eosc-beyond.eu/infrastructures/#{uuid}"
        result = subject.send(:extract_infrastructure_id, uri)

        expect(result).to eq(uuid)
      end

      it "returns nil for nil input" do
        result = subject.send(:extract_infrastructure_id, nil)

        expect(result).to be_nil
      end

      it "returns nil for URI without infrastructures path" do
        result = subject.send(:extract_infrastructure_id, "https://example.com/other/path")

        expect(result).to be_nil
      end
    end
  end

  describe "job configuration" do
    it "uses the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
