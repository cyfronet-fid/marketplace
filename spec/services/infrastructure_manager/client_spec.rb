# frozen_string_literal: true

require "rails_helper"

RSpec.describe InfrastructureManager::Client, type: :service do
  let(:access_token) { "test_access_token" }
  let(:client) { described_class.new(access_token) }
  let(:base_url) { "https://deploy.sandbox.eosc-beyond.eu" }

  let(:sample_tosca_template) { <<~YAML }
      tosca_definitions_version: tosca_simple_yaml_1_2
      topology_template:
        inputs:
          fe_cpus:
            type: integer
            default: 4
          admin_password:
            type: string
            default: "test_password"
        node_templates:
          jupyter_hub:
            type: tosca.nodes.indigo.JupyterHub
            properties:
              admin_password: { get_input: admin_password }
    YAML

  before do
    # Mock HTTP requests by default
    WebMock.disable_net_connect!
  end

  after { WebMock.allow_net_connect! }

  describe "#create_infrastructure" do
    let(:infrastructure_id) { "inf-12345" }
    let(:success_response_body) { infrastructure_id }

    context "when request is successful" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").with(
          headers: {
            "Content-Type" => "text/yaml",
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}"
          },
          body: sample_tosca_template
        ).to_return(status: 200, body: success_response_body, headers: { "Content-Type" => "text/plain" })
      end

      it "sends TOSCA template to IM API" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be true
        expect(result[:data]).to eq(infrastructure_id)
        expect(result[:status_code]).to eq(200)
      end

      it "includes proper authorization header" do
        client.create_infrastructure(sample_tosca_template)

        expect(WebMock).to have_requested(:post, "#{base_url}/infrastructures").with(
          headers: {
            "Authorization" => "Bearer #{access_token}"
          }
        )
      end
    end

    context "when request fails with client error" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 400,
          body: "Bad Request: Invalid TOSCA template"
        )
      end

      it "returns error response" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Client error: 400")
        expect(result[:status_code]).to eq(400)
      end
    end

    context "when request fails with server error" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(status: 500, body: "Internal Server Error")
      end

      it "returns error response" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Server error: 500")
        expect(result[:status_code]).to eq(500)
      end
    end

    context "when network request fails" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").with(
          headers: {
            "Content-Type" => "text/yaml",
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}"
          }
        ).to_raise(Faraday::ConnectionFailed.new("Connection failed"))
      end

      it "handles network errors gracefully" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
        expect(result[:status_code]).to be_nil
      end
    end
  end

  describe "#get_infrastructure_info" do
    let(:infrastructure_id) { "inf-12345" }
    let(:vm_info) { { "uri" => "vm-1", "ip" => "192.168.1.100", "state" => "running" } }

    context "when infrastructure exists" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 200,
          body: [vm_info].to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns infrastructure information" do
        result = client.get_infrastructure_info(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:data]).to be_an(Array)
        expect(result[:data].first).to include("uri" => "vm-1", "state" => "running")
      end
    end

    context "when infrastructure not found" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 404,
          body: "Infrastructure not found"
        )
      end

      it "returns error response" do
        result = client.get_infrastructure_info(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Client error: 404")
      end
    end
  end

  describe "#get_infrastructure_state" do
    let(:infrastructure_id) { "inf-12345" }

    context "when infrastructure is configured" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/state").to_return(
          status: 200,
          body: { "state" => "configured" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns infrastructure state" do
        result = client.get_infrastructure_state(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:data]).to include("state" => "configured")
      end
    end
  end

  describe "#delete_infrastructure" do
    let(:infrastructure_id) { "inf-12345" }

    context "when deletion is successful" do
      before do
        stub_request(:delete, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(status: 200, body: "")
      end

      it "successfully deletes infrastructure" do
        result = client.delete_infrastructure(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:status_code]).to eq(200)
      end
    end
  end

  describe "authorization handling" do
    it "creates proper Bearer authorization header" do
      auth_header = client.send(:authorization_header)

      expect(auth_header).to eq("Bearer #{access_token}")
    end

    context "when no access token provided" do
      let(:client) { described_class.new(nil) }

      it "uses demo token from environment" do
        allow(ENV).to receive(:fetch).with("IM_DEMO_TOKEN", "demo_token_placeholder").and_return("env_demo_token")

        auth_header = client.send(:authorization_header)

        expect(auth_header).to eq("Bearer env_demo_token")
      end
    end
  end

  describe "response parsing" do
    let(:infrastructure_id) { "inf-12345" }

    context "with JSON response" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 200,
          body: { "state" => "configured" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "parses JSON responses correctly" do
        result = client.get_infrastructure_info(infrastructure_id)

        expect(result[:data]).to be_a(Hash)
        expect(result[:data]["state"]).to eq("configured")
      end
    end

    context "with YAML response" do
      let(:yaml_body) { "state: configured\nvm_count: 1" }

      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 200,
          body: yaml_body,
          headers: {
            "Content-Type" => "text/yaml"
          }
        )
      end

      it "parses YAML responses correctly" do
        result = client.get_infrastructure_info(infrastructure_id)

        expect(result[:data]).to be_a(Hash)
        expect(result[:data]["state"]).to eq("configured")
        expect(result[:data]["vm_count"]).to eq(1)
      end
    end

    context "with plain text response" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 200,
          body: "inf-67890",
          headers: {
            "Content-Type" => "text/plain"
          }
        )
      end

      it "returns plain text as string" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:data]).to eq("inf-67890")
      end
    end
  end
end
