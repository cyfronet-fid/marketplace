# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::Deploy, type: :service do
  subject(:deploy) { described_class.call(project_item, client: Adm::Client.new(access_token: "t")) }

  let(:adm_url) { "https://adm.test.example.com/adim" }
  let(:project_item) do
    deployable_service = create(:deployable_service, url: "https://github.com/example/jupyter.yml", pid: "21.T15999/ds")
    offer = create(:offer, service: nil, deployable_service: deployable_service,
                           offer_category: create(:service_category))
    attribute = { id: "fe_cpus", label: "CPUs", type: "input", value_type: "string", value: "8" }
    create(:project_item, offer: offer, properties: [attribute], status: "created", status_type: :created)
  end

  before do
    allow(DeployableService::FetchTemplate).to receive(:call).with("https://github.com/example/jupyter.yml").and_return(
      <<~YAML
        topology_template:
          inputs:
            fe_cpus: { type: integer, default: 4 }
          outputs:
            jupyter_url: { value: "https://example.org" }
            jupyter_ip: { value: "10.0.0.1" }
      YAML
    )
    stub_request(:post, "#{adm_url}/allocations").to_return(
      status: 201,
      body: { id: "alloc-1" }.to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
    stub_request(:post, "#{adm_url}/deployments").to_return(
      status: 202,
      body: { id: "dep-1" }.to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  context "when ADM accepts the deployment" do
    before { deploy }

    it "tracks the ADM deployment in an infrastructure" do
      expect(project_item.reload.infrastructure).to have_attributes(
        state: "creating",
        allocation_id: "alloc-1",
        deployment_id: "dep-1"
      )
    end

    it "records the ADM, the cloud site and the template outputs" do
      expect(project_item.reload.infrastructure).to have_attributes(
        api_base_url: "https://adm.test.example.com/adim/",
        cloud_site: "IISAS-FedCloud",
        output_names: %w[jupyter_url jupyter_ip]
      )
    end

    it "registers the allocation of the default cloud site" do
      expect(WebMock).to have_requested(:post, "#{adm_url}/allocations").with(
        body: hash_including("host" => "https://cloud.ui.savba.sk:5000", "domain" => "ea4f6084f9a74329bd77e466136fd079")
      )
    end

    it "deploys the service application" do
      expect(WebMock).to have_requested(:post, "#{adm_url}/deployments").with(
        body: hash_including("application" => hash_including("id" => "21.T15999/ds"))
      )
    end

    it "sends the order inputs" do
      expect(WebMock).to have_requested(:post, "#{adm_url}/deployments").with(
        body: hash_including("inputs" => ["name" => "fe_cpus", "value" => "8"])
      )
    end

    it "leaves the project item status to the state polling" do
      expect(project_item.reload.status_type).to eq("created")
    end
  end

  context "when ADM rejects the allocation" do
    before do
      stub_request(:post, "#{adm_url}/allocations").to_return(
        status: 403,
        body: { description: "Not a member of the VO" }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
      deploy
    end

    it "marks the infrastructure failed" do
      expect(project_item.reload.infrastructure).to have_attributes(state: "failed",
                                                                    last_error: /Not a member of the VO/)
    end

    it "rejects the project item" do
      expect(project_item.reload).to have_attributes(
        status_type: "rejected",
        status: /\ADeployment failed: .*Not a member of the VO.*Please contact support\.\z/
      )
    end

    it "does not create a deployment" do
      expect(WebMock).not_to have_requested(:post, "#{adm_url}/deployments")
    end
  end

  context "when the deployment cannot be created" do
    before do
      stub_request(:post, "#{adm_url}/deployments").to_return(status: 503)
      deploy
    end

    it "keeps the allocation and marks the infrastructure failed" do
      expect(project_item.reload.infrastructure).to have_attributes(state: "failed", allocation_id: "alloc-1")
    end
  end

  context "when the template cannot be fetched" do
    before do
      project_item
      allow(DeployableService::FetchTemplate).to receive(:call).and_raise(Faraday::ResourceNotFound, "HTTP 404")
      deploy
    end

    it "rejects the project item" do
      expect(project_item.reload).to have_attributes(status_type: "rejected", status: /HTTP 404/)
    end
  end

  context "when the default cloud site is not configured" do
    subject(:deploy) do
      described_class.call(
        project_item,
        client: Adm::Client.new(access_token: "t"),
        config: Rails.application.config_for(:adm).merge(default_cloud_site: "Unknown-Site")
      )
    end

    before { deploy }

    it "marks the infrastructure failed" do
      expect(project_item.reload.infrastructure).to have_attributes(state: "failed", last_error: /Unknown-Site/)
    end
  end
end
