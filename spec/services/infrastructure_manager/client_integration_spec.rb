# frozen_string_literal: true

require "rails_helper"

RSpec.describe InfrastructureManager::Client, type: :service, integration: true do
  let(:client) { described_class.new(nil, "IISAS-FedCloud") }

  let(:sample_tosca_template) { <<~YAML }
      tosca_definitions_version: tosca_simple_yaml_1_0

      topology_template:
        node_templates:
          simple_compute:
            type: tosca.nodes.indigo.Compute
            capabilities:
              host:
                properties:
                  num_cpus: 1
                  mem_size: 1 GiB
              os:
                properties:
                  distribution: ubuntu
                  type: linux
                  version: 22.04
    YAML

  describe "#create_infrastructure", :integration do
    context "when valid credentials and template provided" do
      it "successfully creates infrastructure" do
        # This test requires real EGI credentials and should only run in integration environment
        skip "Integration test requires real EGI credentials" unless ENV["RUN_INTEGRATION_TESTS"]

        result = client.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be true
        expect(result[:status_code]).to eq(200)
        expect(result[:data]).to have_key("uri")

        # Clean up would require manual intervention since we removed delete method
        if result[:success] && result[:data]["uri"]
          infrastructure_id = result[:data]["uri"].split("/").last
          puts "Created infrastructure: #{infrastructure_id} - manual cleanup required"
        end
      end
    end

    context "when invalid credentials provided" do
      let(:client_with_bad_token) { described_class.new("invalid_token", "IISAS-FedCloud") }

      it "returns authentication error" do
        skip "Integration test requires network access" unless ENV["RUN_INTEGRATION_TESTS"]

        result = client_with_bad_token.create_infrastructure(sample_tosca_template)

        expect(result[:success]).to be false
        expect(result[:status_code]).to be_between(400, 499)
      end
    end
  end
end
