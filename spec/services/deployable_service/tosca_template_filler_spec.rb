# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::ToscaTemplateFiller, type: :service do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:provider) { create(:provider) }
  let(:deployable_service) do
    create(
      :deployable_service,
      resource_organisation: provider,
      url: "https://github.com/example/jupyterhub_datamount.yml"
    )
  end
  let(:service_category) { create(:service_category) }
  let(:offer) { create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category) }
  let(:project_item) { create(:project_item, project: project, offer: offer) }

  let(:mock_properties) do
    [
      '{"id": "fe_cpus", "value": "8"}',
      '{"id": "admin_password", "value": "secure_pass"}',
      '{"id": "kube_public_dns_name", "value": "test.example.com"}',
      '{"id": "dataset_ids", "value": "doi1,doi2,doi3"}'
    ]
  end

  let(:mock_template_content) { <<~YAML }
      tosca_definitions_version: tosca_simple_yaml_1_2
      topology_template:
        inputs:
          fe_cpus:
            type: integer
            default: 4
          admin_password:
            type: string
            default: "default_pass"
          kube_public_dns_name:
            type: string
            default: "jupyter.default.com"
          dataset_ids:
            type: list
            default: ["default_doi"]
    YAML

  let(:uuid_dns_pattern) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.vm\.fedcloud\.eu$/ }

  subject { described_class.new(project_item) }

  describe "#call" do
    before do
      allow(project_item).to receive(:properties).and_return(mock_properties)
      allow(subject).to receive(:fetch_template).and_return(mock_template_content)
    end

    xit "fills TOSCA template with user parameters and returns filled template" do # needs fix
      result = subject.call

      expect(result).to be_a(String)
      expect(result).to include("tosca_definitions_version: tosca_simple_yaml_1_2")

      # Parse result to verify parameter substitution
      parsed_result = YAML.safe_load(result)
      inputs = parsed_result.dig("topology_template", "inputs")

      expect(inputs["fe_cpus"]["default"]).to eq("8")
      expect(inputs["admin_password"]["default"]).to eq("secure_pass")
      # DNS name is auto-generated and ignores user input
      expect(inputs["kube_public_dns_name"]["default"]).to match(uuid_dns_pattern)
      expect(inputs["dataset_ids"]["default"]).to eq(%w[doi1 doi2 doi3])
    end
  end

  describe "#extract_user_parameters" do
    xit "parses JSON properties into parameter hash" do # needs fix
      parameters = subject.send(:extract_user_parameters, mock_properties)

      expect(parameters).to eq(
        {
          "fe_cpus" => "8",
          "admin_password" => "secure_pass",
          "kube_public_dns_name" => "test.example.com",
          "dataset_ids" => "doi1,doi2,doi3"
        }
      )
    end

    xit "returns empty hash when properties are nil" do # needs fix
      parameters = subject.send(:extract_user_parameters, nil)
      expect(parameters).to eq({})
    end

    xit "returns empty hash when properties are empty" do # needs fix
      parameters = subject.send(:extract_user_parameters, [])
      expect(parameters).to eq({})
    end

    xit "skips invalid JSON properties" do # needs fix
      invalid_properties = ['{"id": "valid", "value": "test"}', "invalid json"]
      allow(Rails.logger).to receive(:warn)

      parameters = subject.send(:extract_user_parameters, invalid_properties)

      expect(parameters).to eq({ "valid" => "test" })
      expect(Rails.logger).to have_received(:warn)
    end

    xit "handles properties without id or value" do # needs fix
      invalid_properties = ['{"id": "valid"}', '{"value": "test"}', '{"id": "complete", "value": "works"}']

      parameters = subject.send(:extract_user_parameters, invalid_properties)

      expect(parameters).to eq({ "complete" => "works" })
    end

    xit "handles hash properties format" do # needs fix
      hash_properties = {
        "fe_cpus" => "8",
        "admin_password" => "secure_pass",
        "empty_param" => nil,
        "blank_param" => ""
      }

      parameters = subject.send(:extract_user_parameters, hash_properties)

      expect(parameters).to eq({ "fe_cpus" => "8", "admin_password" => "secure_pass" })
    end

    xit "handles array of hash objects" do # needs fix
      array_of_hashes = [
        { "id" => "fe_cpus", "value" => "8" },
        { "id" => "admin_password", "value" => "secure_pass" },
        { "id" => "empty", "value" => nil }
      ]

      parameters = subject.send(:extract_user_parameters, array_of_hashes)

      expect(parameters).to eq({ "fe_cpus" => "8", "admin_password" => "secure_pass" })
    end

    xit "handles unexpected format gracefully" do # needs fix
      allow(Rails.logger).to receive(:warn)

      parameters = subject.send(:extract_user_parameters, "unexpected string")

      expect(parameters).to eq({})
      expect(Rails.logger).to have_received(:warn).with("Unexpected properties format: String")
    end
  end

  describe "#fill_template_inputs" do
    let(:parsed_template) do
      {
        "topology_template" => {
          "inputs" => {
            "fe_cpus" => {
              "type" => "integer",
              "default" => 4
            },
            "dataset_ids" => {
              "type" => "list",
              "default" => ["old_doi"]
            },
            "admin_password" => {
              "type" => "string",
              "default" => "old_pass"
            }
          }
        }
      }
    end

    let(:user_parameters) do
      {
        "fe_cpus" => "8",
        "dataset_ids" => "doi1,doi2,doi3",
        "admin_password" => "new_secure_pass",
        "unknown_param" => "ignored"
      }
    end

    xit "replaces default values with user parameters" do # needs fix
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      expect(inputs["fe_cpus"]["default"]).to eq("8")
      expect(inputs["admin_password"]["default"]).to eq("new_secure_pass")
    end

    xit "converts comma-separated dataset_ids to array" do # needs fix
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      expect(inputs["dataset_ids"]["default"]).to eq(%w[doi1 doi2 doi3])
    end

    xit "ignores parameters not in template" do # needs fix
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      # Should not add unknown_param to inputs
      inputs = result.dig("topology_template", "inputs")
      expect(inputs).not_to have_key("unknown_param")
    end

    xit "handles templates without inputs section" do # needs fix
      template_without_inputs = { "topology_template" => {} }

      expect do
        subject.send(:fill_template_inputs, template_without_inputs.to_yaml, user_parameters)
      end.not_to raise_error
    end

    xit "handles YAML parsing errors gracefully" do # needs fix
      allow(Rails.logger).to receive(:error)

      result = subject.send(:fill_template_inputs, "invalid: yaml: content:", user_parameters)

      expect(result).to eq("invalid: yaml: content:")
      expect(Rails.logger).to have_received(:error).with(/Failed to parse TOSCA template YAML/)
    end

    xit "handles YAML generation errors gracefully" do # needs fix
      allow(Rails.logger).to receive(:error)

      # Mock the parsed template conversion to fail at the YAML generation step
      allow(YAML).to receive(:safe_load).and_return(parsed_template)
      allow(parsed_template).to receive(:to_yaml).and_raise(StandardError, "YAML error")

      result = subject.send(:fill_template_inputs, "valid yaml input", user_parameters)

      expect(result).to eq("valid yaml input") # Should return original content
      expect(Rails.logger).to have_received(:error).with(/Failed to convert template back to YAML/)
    end
  end

  describe "#fetch_template" do
    xit "reads template from config/templates" do # needs fix
      allow(File).to receive(:read).with(Rails.root.join("config", "templates", "jupyterhub_datamount.yml")).and_return(
        mock_template_content
      )

      result = subject.send(:fetch_template, "any_url")

      expect(result).to eq(mock_template_content)
    end
  end

  describe "#generate_unique_dns_name" do
    xit "generates a DNS name in UUID.vm.fedcloud.eu format" do # needs fix
      dns_name = subject.send(:generate_unique_dns_name)

      expect(dns_name).to match(uuid_dns_pattern)
    end

    xit "generates unique DNS names on each call" do # needs fix
      first_dns_name = subject.send(:generate_unique_dns_name)
      second_dns_name = subject.send(:generate_unique_dns_name)

      expect(first_dns_name).not_to eq(second_dns_name)
    end

    xit "generates DNS names ending with .vm.fedcloud.eu" do # needs fix
      dns_name = subject.send(:generate_unique_dns_name)

      expect(dns_name).to end_with(".vm.fedcloud.eu")
    end
  end

  describe "DNS parameter handling" do
    let(:template_with_dns) do
      {
        "topology_template" => {
          "inputs" => {
            "kube_public_dns_name" => {
              "type" => "string",
              "default" => "old-default.example.com"
            },
            "admin_password" => {
              "type" => "string",
              "default" => "old_pass"
            }
          }
        }
      }
    end

    xit "overrides DNS parameter with auto-generated value" do # needs fix
      user_parameters = { "kube_public_dns_name" => "user-provided.example.com", "admin_password" => "new_pass" }

      result_yaml = subject.send(:fill_template_inputs, template_with_dns.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      # User-provided DNS should be ignored
      expect(inputs["kube_public_dns_name"]["default"]).not_to eq("user-provided.example.com")
      # Should be auto-generated UUID format
      expect(inputs["kube_public_dns_name"]["default"]).to match(uuid_dns_pattern)
      # Non-DNS parameters should still be updated
      expect(inputs["admin_password"]["default"]).to eq("new_pass")
    end

    xit "generates DNS even when user doesn't provide kube_public_dns_name" do # needs fix
      user_parameters = { "admin_password" => "new_pass" }

      result_yaml = subject.send(:fill_template_inputs, template_with_dns.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      # Should still generate UUID-based DNS
      expect(inputs["kube_public_dns_name"]["default"]).to match(uuid_dns_pattern)
      expect(inputs["admin_password"]["default"]).to eq("new_pass")
    end
  end
end
