# frozen_string_literal: true

require "rails_helper"

RSpec.describe InfrastructureManager::Client, type: :service do
  let(:access_token) { "test_access_token" }
  let(:site) { "IISAS-FedCloud" }
  let(:client) { described_class.new(access_token, site) }
  let(:base_url) { "https://im.test.example.com" }

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

      it "converts response to HashWithIndifferentAccess" do
        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:data]).to be_a(ActiveSupport::HashWithIndifferentAccess)
        # Can access with both string and symbol keys
        expect(result[:data]["status"]).to eq("configured")
        expect(result[:data][:status]).to eq("configured")
        expect(result[:data]["uri"]).to eq("http://example.com")
        expect(result[:data][:uri]).to eq("http://example.com")
      end
    end

    context "with nested hash response" do
      let(:nested_json) do
        { "outputs" => { "jupyterhub_url" => "https://example.vm.fedcloud.eu/jupyterhub/" } }.to_json
      end

      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 200,
          body: nested_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "converts nested hashes to HashWithIndifferentAccess" do
        result = client.create_infrastructure(sample_tosca_template)

        # Can access nested hash with both string and symbol keys
        expect(result[:data]["outputs"]["jupyterhub_url"]).to eq("https://example.vm.fedcloud.eu/jupyterhub/")
        expect(result[:data][:outputs][:jupyterhub_url]).to eq("https://example.vm.fedcloud.eu/jupyterhub/")
        expect(result[:data]["outputs"][:jupyterhub_url]).to eq("https://example.vm.fedcloud.eu/jupyterhub/")
        expect(result[:data][:outputs]["jupyterhub_url"]).to eq("https://example.vm.fedcloud.eu/jupyterhub/")
      end
    end

    context "with array of hashes response" do
      let(:array_json) { { "radl" => [{ "class" => "system", "net_interface.1.ip" => "192.168.1.1" }] }.to_json }

      before do
        stub_request(:post, "#{base_url}/infrastructures").to_return(
          status: 200,
          body: array_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "converts hashes within arrays to HashWithIndifferentAccess" do
        result = client.create_infrastructure(sample_tosca_template)

        # Can access array elements with both string and symbol keys
        expect(result[:data]["radl"][0]["class"]).to eq("system")
        expect(result[:data][:radl][0][:class]).to eq("system")
        expect(result[:data]["radl"][0]["net_interface.1.ip"]).to eq("192.168.1.1")
        expect(result[:data][:radl][0][:"net_interface.1.ip"]).to eq("192.168.1.1")
      end
    end
  end

  describe "#get_state" do
    let(:infrastructure_id) { "inf-12345" }

    context "when request is successful" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/state").to_return(
          status: 200,
          body: { "state" => "running" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns the infrastructure state" do
        result = client.get_state(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:data]["state"]).to eq("running")
      end
    end

    context "when infrastructure is not found" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/state").to_return(
          status: 404,
          body: { "message" => "Not found" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns error response" do
        result = client.get_state(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(404)
      end
    end

    context "when network request fails" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/state").to_raise(Faraday::TimeoutError)
      end

      it "handles network errors gracefully" do
        result = client.get_state(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
      end
    end
  end

  describe "#destroy_infrastructure" do
    let(:infrastructure_id) { "inf-12345" }

    context "when request is successful" do
      before do
        stub_request(:delete, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 200,
          body: "",
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns success" do
        result = client.destroy_infrastructure(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:status_code]).to eq(200)
      end
    end

    context "when infrastructure is not found" do
      before do
        stub_request(:delete, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 404,
          body: { "message" => "Not found" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns error response" do
        result = client.destroy_infrastructure(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(404)
      end
    end

    context "when permission denied" do
      before do
        stub_request(:delete, "#{base_url}/infrastructures/#{infrastructure_id}").to_return(
          status: 403,
          body: { "message" => "Forbidden" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns client error response" do
        result = client.destroy_infrastructure(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(403)
        expect(result[:error]).to include("Client error")
      end
    end

    context "when network request fails" do
      before do
        stub_request(:delete, "#{base_url}/infrastructures/#{infrastructure_id}").to_raise(Faraday::ConnectionFailed)
      end

      it "handles network errors gracefully" do
        result = client.destroy_infrastructure(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
      end
    end
  end

  describe "#get_outputs" do
    let(:infrastructure_id) { "inf-12345" }

    context "when request is successful" do
      let(:outputs) { { "outputs" => { "jupyterhub_url" => "https://jupyter.example.com" } } }

      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/outputs").to_return(
          status: 200,
          body: outputs.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns the infrastructure outputs" do
        result = client.get_outputs(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:data]["outputs"]["jupyterhub_url"]).to eq("https://jupyter.example.com")
      end
    end

    context "when infrastructure is not found" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/outputs").to_return(
          status: 404,
          body: { "message" => "Not found" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns error response" do
        result = client.get_outputs(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(404)
      end
    end

    context "when outputs not yet available" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/outputs").to_return(
          status: 200,
          body: { "outputs" => {} }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns empty outputs" do
        result = client.get_outputs(infrastructure_id)

        expect(result[:success]).to be true
        expect(result[:data]["outputs"]).to eq({})
      end
    end

    context "when network request fails" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/outputs").to_raise(Faraday::TimeoutError)
      end

      it "handles network errors gracefully" do
        result = client.get_outputs(infrastructure_id)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
      end
    end
  end

  describe "#get_vm_info" do
    let(:infrastructure_id) { "inf-12345" }
    let(:vm_id) { "0" }

    context "when request is successful" do
      let(:vm_info) { { "radl" => [{ "class" => "system", "net_interface.0.ip" => "192.168.1.1", "cpu.count" => 4 }] } }

      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/vms/#{vm_id}").to_return(
          status: 200,
          body: vm_info.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns the VM information" do
        result = client.get_vm_info(infrastructure_id, vm_id)

        expect(result[:success]).to be true
        expect(result[:data]["radl"][0]["class"]).to eq("system")
        expect(result[:data]["radl"][0]["net_interface.0.ip"]).to eq("192.168.1.1")
      end
    end

    context "when VM is not found" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/vms/#{vm_id}").to_return(
          status: 404,
          body: { "message" => "Not found" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns error response" do
        result = client.get_vm_info(infrastructure_id, vm_id)

        expect(result[:success]).to be false
        expect(result[:status_code]).to eq(404)
      end
    end

    context "when network request fails" do
      before do
        stub_request(:get, "#{base_url}/infrastructures/#{infrastructure_id}/vms/#{vm_id}").to_raise(
          Faraday::ConnectionFailed
        )
      end

      it "handles network errors gracefully" do
        result = client.get_vm_info(infrastructure_id, vm_id)

        expect(result[:success]).to be false
        expect(result[:error]).to include("HTTP request failed")
      end
    end
  end
end
