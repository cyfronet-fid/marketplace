# frozen_string_literal: true

require "rails_helper"

RSpec.describe InfrastructureManager::Client, type: :service do
  let(:access_token) { "test_access_token" }
  let(:site) { "IISAS-FedCloud" }
  let(:client) { described_class.new(access_token, site) }
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

  before { WebMock.disable_net_connect! }

  after { WebMock.allow_net_connect! }

  describe "#create_infrastructure" do
    let(:success_response_body) do
      { "uri" => "https://deploy.sandbox.eosc-beyond.eu/infrastructures/inf-12345" }.to_json
    end
    let(:expected_auth_header) do
      "id = im; type = InfrastructureManager; token = #{access_token}\\n" \
        "id = egi; type = EGI; vo = eosc-beyond.eu; token = #{access_token}; host = #{site}"
    end

    context "when request is successful" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").with(
          headers: {
            "Content-Type" => "text/yaml",
            "Accept" => "application/json",
            "Authorization" => expected_auth_header
          },
          body: sample_tosca_template
        ).to_return(status: 200, body: success_response_body, headers: { "Content-Type" => "application/json" })
      end

      it "sends TOSCA template to IM API" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be true
        expect(result[:status_code]).to eq(200)
        expect(result[:data]["uri"]).to include("inf-12345")
      end

      it "includes proper authorization header with site and eosc-beyond.eu VO" do
        client.create_infrastructure(sample_tosca_template)

        expect(WebMock).to have_requested(:post, "#{base_url}/infrastructures").with(
          headers: {
            "Authorization" => expected_auth_header
          }
        )
      end
    end

    context "when client error occurs" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 400,
          body: { "message" => "Bad Request", "code" => 400 }.to_json
        )
      end

      it "returns error response" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(400)
        expect(result[:error]).to include("Client error")
      end
    end

    context "when server error occurs" do
      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 500,
          body: { "message" => "Internal Server Error", "code" => 500 }.to_json
        )
      end

      it "returns server error response" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(500)
        expect(result[:error]).to include("Server error")
      end
    end

    context "when network request fails" do
      before { stub_request(:post, "#{base_url}/infrastructures").to_raise(Faraday::ConnectionFailed) }

      it "handles network errors gracefully" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
        expect(result[:status_code]).to be_nil
      end
    end
  end

  describe "authorization handling" do
    context "when access token is provided" do
      it "uses provided access token in authorization header" do
        auth_header = client.send(:authorization_header)

        expect(auth_header).to include("token = #{access_token}")
        expect(auth_header).to include("vo = eosc-beyond.eu")
        expect(auth_header).to include("host = #{site}")
      end
    end

    context "when no access token provided" do
      let(:client) { described_class.new(nil, site) }

      before do
        allow(ENV).to receive(:fetch).with("EGI_ACCESS_TOKEN", nil).and_return("env_token")
        allow(ENV).to receive(:fetch).with("EGI_REFRESH_ACCESS_TOKEN", nil).and_return(nil)
      end

      it "uses token from environment" do
        auth_header = client.send(:authorization_header)

        expect(auth_header).to include("token = env_token")
      end
    end

    context "when no tokens are available" do
      let(:client) { described_class.new(nil, site) }

      before do
        allow(ENV).to receive(:fetch).with("EGI_ACCESS_TOKEN", nil).and_return(nil)
        allow(ENV).to receive(:fetch).with("EGI_REFRESH_ACCESS_TOKEN", nil).and_return(nil)
        allow(Rails.cache).to receive(:read).with("egi_access_token").and_return(nil)
      end

      it "raises an error when no tokens are available" do
        expect { client.send(:authorization_header) }.to raise_error(StandardError, /No EGI access token available/)
      end
    end
  end

  describe "response parsing" do
    context "with JSON response" do
      let(:json_body) { { "status" => "configured", "uri" => "http://example.com" }.to_json }

      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 200,
          body: json_body,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "parses JSON responses correctly" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be true
        expect(result[:data]).to be_a(Hash)
        expect(result[:data]["status"]).to eq("configured")
      end
    end
  end
end
