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

  subject { described_class.new(project_item) }

  describe "#call" do
    before do
      allow(project_item).to receive(:properties).and_return(mock_properties)
      allow(subject).to receive(:fetch_template).and_return(mock_template_content)
    end

    it "fills TOSCA template with user parameters and returns filled template" do
      result = subject.call

      expect(result).to be_a(String)
      expect(result).to include("tosca_definitions_version: tosca_simple_yaml_1_2")

      # Parse result to verify parameter substitution
      parsed_result = YAML.safe_load(result)
      inputs = parsed_result.dig("topology_template", "inputs")

      expect(inputs["fe_cpus"]["default"]).to eq("8")
      expect(inputs["admin_password"]["default"]).to eq("secure_pass")
      expect(inputs["kube_public_dns_name"]["default"]).to eq("test.example.com")
      expect(inputs["dataset_ids"]["default"]).to eq(%w[doi1 doi2 doi3])
    end

    context "when template file does not exist" do
      before do
        allow(subject).to receive(:fetch_template).and_call_original
        allow(File).to receive(:exist?).and_return(false)
      end

      it "uses fallback template and still fills it correctly" do
        result = subject.call

        expect(result).to include("tosca_definitions_version: tosca_simple_yaml_1_2")
        expect(result).to include("fe_cpus")
        expect(result).to include("dataset_ids")

        # Parse result to verify parameter substitution in fallback template
        parsed_result = YAML.safe_load(result)
        inputs = parsed_result.dig("topology_template", "inputs")

        expect(inputs["fe_cpus"]["default"]).to eq("8")
        expect(inputs["admin_password"]["default"]).to eq("secure_pass")
      end
    end
  end

  describe "#extract_user_parameters" do
    it "parses JSON properties into parameter hash" do
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

    it "returns empty hash when properties are nil" do
      parameters = subject.send(:extract_user_parameters, nil)
      expect(parameters).to eq({})
    end

    it "returns empty hash when properties are empty" do
      parameters = subject.send(:extract_user_parameters, [])
      expect(parameters).to eq({})
    end

    it "skips invalid JSON properties" do
      invalid_properties = ['{"id": "valid", "value": "test"}', "invalid json"]
      allow(Rails.logger).to receive(:warn)

      parameters = subject.send(:extract_user_parameters, invalid_properties)

      expect(parameters).to eq({ "valid" => "test" })
      expect(Rails.logger).to have_received(:warn)
    end

    it "handles properties without id or value" do
      invalid_properties = ['{"id": "valid"}', '{"value": "test"}', '{"id": "complete", "value": "works"}']

      parameters = subject.send(:extract_user_parameters, invalid_properties)

      expect(parameters).to eq({ "complete" => "works" })
    end

    it "handles hash properties format" do
      hash_properties = {
        "fe_cpus" => "8",
        "admin_password" => "secure_pass",
        "empty_param" => nil,
        "blank_param" => ""
      }

      parameters = subject.send(:extract_user_parameters, hash_properties)

      expect(parameters).to eq({ "fe_cpus" => "8", "admin_password" => "secure_pass" })
    end

    it "handles array of hash objects" do
      array_of_hashes = [
        { "id" => "fe_cpus", "value" => "8" },
        { "id" => "admin_password", "value" => "secure_pass" },
        { "id" => "empty", "value" => nil }
      ]

      parameters = subject.send(:extract_user_parameters, array_of_hashes)

      expect(parameters).to eq({ "fe_cpus" => "8", "admin_password" => "secure_pass" })
    end

    it "handles unexpected format gracefully" do
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

    it "replaces default values with user parameters" do
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      expect(inputs["fe_cpus"]["default"]).to eq("8")
      expect(inputs["admin_password"]["default"]).to eq("new_secure_pass")
    end

    it "converts comma-separated dataset_ids to array" do
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      inputs = result.dig("topology_template", "inputs")
      expect(inputs["dataset_ids"]["default"]).to eq(%w[doi1 doi2 doi3])
    end

    it "ignores parameters not in template" do
      result_yaml = subject.send(:fill_template_inputs, parsed_template.to_yaml, user_parameters)
      result = YAML.safe_load(result_yaml)

      # Should not add unknown_param to inputs
      inputs = result.dig("topology_template", "inputs")
      expect(inputs).not_to have_key("unknown_param")
    end

    it "handles templates without inputs section" do
      template_without_inputs = { "topology_template" => {} }

      expect do
        subject.send(:fill_template_inputs, template_without_inputs.to_yaml, user_parameters)
      end.not_to raise_error
    end

    it "handles YAML parsing errors gracefully" do
      allow(Rails.logger).to receive(:error)

      result = subject.send(:fill_template_inputs, "invalid: yaml: content:", user_parameters)

      expect(result).to eq("invalid: yaml: content:")
      expect(Rails.logger).to have_received(:error).with(/Failed to parse TOSCA template YAML/)
    end

    it "handles YAML generation errors gracefully" do
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
    context "when template file exists" do
      before do
        allow(File).to receive(:exist?).with(
          Rails.root.join("config", "templates", "jupyterhub_datamount.yml")
        ).and_return(true)
        allow(File).to receive(:read).with(
          Rails.root.join("config", "templates", "jupyterhub_datamount.yml")
        ).and_return(mock_template_content)
      end

      it "reads template from config/templates" do
        result = subject.send(:fetch_template, "any_url")

        expect(result).to eq(mock_template_content)
      end
    end

    context "when template file does not exist" do
      before { allow(File).to receive(:exist?).and_return(false) }

      it "returns basic jupyter template as fallback" do
        result = subject.send(:fetch_template, "any_url")

        expect(result).to include("tosca_definitions_version")
        expect(result).to include("fe_cpus:")
        expect(result).to include("dataset_ids:")
        expect(result).to include("admin_password:")
      end
    end
  end
end
