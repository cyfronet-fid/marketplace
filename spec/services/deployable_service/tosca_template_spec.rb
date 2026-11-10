# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::ToscaTemplate, type: :service do
  subject(:template) { described_class.new(content) }

  context "with inputs and outputs" do
    let(:content) { <<~YAML }
      tosca_definitions_version: tosca_simple_yaml_1_0
      topology_template:
        inputs:
          jupyter_token:
            type: string
            default: changeme
          dns_name:
            type: string
        outputs:
          jupyter_url:
            value: { concat: [ 'https://', get_input: dns_name ] }
          jupyter_ip:
            value: { get_attribute: [ front, public_address, 0 ] }
    YAML

    it "returns the declared inputs" do
      expect(template.inputs.keys).to eq(%w[jupyter_token dns_name])
    end

    it "returns the input definitions" do
      expect(template.inputs["jupyter_token"]).to eq("type" => "string", "default" => "changeme")
    end

    it "returns the output names in declaration order" do
      expect(template.output_names).to eq(%w[jupyter_url jupyter_ip])
    end
  end

  context "without a topology template" do
    let(:content) { "tosca_definitions_version: tosca_simple_yaml_1_0\n" }

    it "has no inputs" do
      expect(template.inputs).to eq({})
    end

    it "has no outputs" do
      expect(template.output_names).to eq([])
    end
  end

  context "with content that is not a YAML mapping" do
    let(:content) { "404: Not Found" }

    it "has no inputs" do
      expect(template.inputs).to eq({})
    end
  end

  context "with invalid YAML" do
    let(:content) { "topology_template: [" }

    it "raises a syntax error" do
      expect { template }.to raise_error(Psych::SyntaxError)
    end
  end

  describe ".fetch" do
    before do
      allow(DeployableService::FetchTemplate).to receive(:call).with("https://github.com/example/jupyter.yml").and_return(
        "topology_template:\n  inputs:\n    fe_cpus: { type: integer }\n"
      )
    end

    it "parses the template fetched from the URL" do
      expect(described_class.fetch("https://github.com/example/jupyter.yml").inputs.keys).to eq(["fe_cpus"])
    end
  end
end
