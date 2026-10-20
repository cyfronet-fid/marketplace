# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationDeploymentManager::Client, type: :service do
  let(:base_url) { "https://adm.test.example.com/adim" }
  let(:client) { described_class.new(access_token: "adm-token") }
  let(:json_headers) { { "Content-Type" => "application/json" } }

  describe "authentication" do
    let!(:stub) do
      stub_request(:get, "#{base_url}/deployment/dep-1").with(headers: { "Authorization" => authorization }).to_return(
        status: 200,
        body: { id: "dep-1", status: "pending" }.to_json,
        headers: json_headers
      )
    end

    context "with an access token" do
      let(:authorization) { "Bearer adm-token" }

      it "sends it as a bearer token" do
        client.deployment("dep-1")
        expect(stub).to have_been_requested
      end
    end

    context "without an access token" do
      let(:authorization) { "Bearer service-token" }

      before { allow(Checkin::ServiceAccountToken).to receive(:call).and_return("service-token") }

      it "uses the service account token" do
        described_class.new.deployment("dep-1")
        expect(stub).to have_been_requested
      end
    end
  end

  describe "#create_allocation" do
    subject(:create_allocation) { client.create_allocation(host: "https://cloud.example.com:5000", domain: "project-id") }

    let(:allocation_body) do
      {
        kind: "EGIComputeEnvironment",
        authVersion: "3.x-oidc",
        userName: "egi.eu",
        tenant: "openid",
        domain: "project-id",
        host: "https://cloud.example.com:5000"
      }
    end

    before { stub_request(:post, "#{base_url}/allocations").with(body: allocation_body.to_json).to_return(response) }

    context "when the allocation is created" do
      let(:response) do
        {
          status: 201,
          body: { kind: "AllocationId", id: "alloc-1", infoLink: "#{base_url}/allocation/alloc-1" }.to_json,
          headers: json_headers
        }
      end

      it { is_expected.to eq("alloc-1") }
    end

    context "when the allocation exists and is returned in the body" do
      let(:response) do
        {
          status: 200,
          body: { id: "existing-alloc", self: "#{base_url}/allocation/existing-alloc" }.to_json,
          headers: json_headers
        }
      end

      it { is_expected.to eq("existing-alloc") }
    end

    context "when the allocation exists and is returned in the 303 Location header" do
      let(:response) { { status: 303, headers: { "Location" => "#{base_url}/allocation/existing-alloc" } } }

      it { is_expected.to eq("existing-alloc") }
    end

    context "when no allocation id is returned" do
      let(:response) { { status: 303 } }

      it "raises an error" do
        expect { create_allocation }.to raise_error(ApplicationDeploymentManager::Error, /allocation id/)
      end
    end
  end

  describe "#create_deployment" do
    subject(:create_deployment) do
      client.create_deployment(
        allocation_id: "alloc-1",
        application_id: "21.T15999/abc",
        inputs: {
          "fe_cpus" => 4,
          "dataset_ids" => %w[doi1 doi2]
        }
      )
    end

    let(:deployment_body) do
      {
        allocation: {
          kind: "AllocationId",
          id: "alloc-1",
          infoLink: "#{base_url}/allocation/alloc-1"
        },
        application: {
          kind: "ApplicationId",
          id: "21.T15999/abc",
          infoLink: "#{base_url}/application/21.T15999%2Fabc"
        },
        inputs: [{ name: "fe_cpus", value: 4 }, { name: "dataset_ids", value: %w[doi1 doi2] }]
      }
    end

    before do
      stub_request(:post, "#{base_url}/deployments").with(body: deployment_body.to_json).to_return(
        status: 202,
        body: { kind: "DeploymentId", id: "dep-1", infoLink: "#{base_url}/deployment/dep-1" }.to_json,
        headers: json_headers
      )
    end

    it "posts the allocation, the application and the inputs and returns the deployment id" do
      expect(create_deployment).to eq("dep-1")
    end
  end

  describe "#deployment" do
    subject(:deployment) { client.deployment("dep-1") }

    before do
      stub_request(:get, "#{base_url}/deployment/dep-1").to_return(
        status: status,
        body: body.to_json,
        headers: json_headers
      )
    end

    context "when the deployment has outputs" do
      let(:status) { 200 }
      let(:body) do
        {
          kind: "DeploymentInfo",
          id: "dep-1",
          status: "configured",
          details: "All VMs configured",
          outputs: [{ name: "jupyterhub_url", value: "https://hub.example.com" }, { name: "ip", value: "10.0.0.1" }]
        }
      end

      it "returns the status and details" do
        expect(deployment).to have_attributes(id: "dep-1", status: "configured", details: "All VMs configured")
      end

      it "returns the outputs as a hash" do
        expect(deployment.outputs).to eq("jupyterhub_url" => "https://hub.example.com", "ip" => "10.0.0.1")
      end
    end

    context "when the deployment has no outputs" do
      let(:status) { 200 }
      let(:body) { { id: "dep-1", status: "pending", outputs: nil } }

      it "returns empty outputs" do
        expect(deployment.outputs).to eq({})
      end
    end

    context "when the deployment is unknown" do
      let(:status) { 404 }
      let(:body) { { id: "not_found", description: "Deployment not found" } }

      it "raises NotFound" do
        expect { deployment }.to raise_error(ApplicationDeploymentManager::NotFound, /Deployment not found/)
      end
    end

    context "when ADM fails" do
      let(:status) { 503 }
      let(:body) { { id: "unavailable", description: "Try again later" } }

      it "raises an error with the ADM description" do
        expect { deployment }.to raise_error(ApplicationDeploymentManager::Error, /503.*Try again later/)
      end
    end

    context "when access is forbidden" do
      let(:status) { 403 }
      let(:body) { { description: "Forbidden" } }

      it "raises an error that is not NotFound" do
        expect { deployment }.to raise_error(
          an_instance_of(ApplicationDeploymentManager::Error).and(having_attributes(message: /403: Forbidden/))
        )
      end
    end
  end

  describe "#deployment path" do
    let!(:stub) do
      stub_request(:get, "#{base_url}/deployment/dep%2F1").to_return(
        status: 200,
        body: { id: "dep/1", status: "pending" }.to_json,
        headers: json_headers
      )
    end

    it "escapes the deployment id" do
      client.deployment("dep/1")
      expect(stub).to have_been_requested
    end
  end

  describe "#deployment timeouts" do
    before { stub_request(:get, "#{base_url}/deployment/dep-1").to_timeout }

    it "wraps them in an error" do
      expect { client.deployment("dep-1") }.to raise_error(ApplicationDeploymentManager::Error, /Faraday::/)
    end
  end

  describe "#delete_deployment" do
    let!(:stub) do
      stub_request(:delete, "#{base_url}/deployment/dep-1").to_return(
        status: 202,
        body: { message: "Deleting" }.to_json,
        headers: json_headers
      )
    end

    it "returns true" do
      expect(client.delete_deployment("dep-1")).to be(true)
    end

    it "sends the delete request" do
      client.delete_deployment("dep-1")
      expect(stub).to have_been_requested
    end
  end
end
