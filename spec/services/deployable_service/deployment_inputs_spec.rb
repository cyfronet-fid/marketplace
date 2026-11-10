# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::DeploymentInputs, type: :service do
  subject(:inputs) { described_class.call(project_item, DeployableService::ToscaTemplate.new(template_content)) }

  let(:project_item) { create(:project_item) }
  let(:template_content) { <<~YAML }
    topology_template:
      inputs:
        fe_cpus:
          type: integer
          default: 4
        admin_password:
          type: string
        dataset_ids:
          type: list
  YAML

  before { allow(project_item).to receive(:properties).and_return(properties) }

  context "with JSON string properties" do
    let(:properties) do
      [
        '{"id": "fe_cpus", "value": "8"}',
        '{"id": "admin_password", "value": "secure_pass"}',
        '{"id": "not_in_template", "value": "ignored"}'
      ]
    end

    it "returns the values of the inputs declared in the template" do
      expect(inputs).to eq("fe_cpus" => "8", "admin_password" => "secure_pass")
    end
  end

  context "with attribute hash properties" do
    let(:properties) do
      [
        { "id" => "fe_cpus", "label" => "CPUs", "type" => "input", "value_type" => "integer", "value" => "2" },
        { "id" => "admin_password", "label" => "Password", "type" => "input", "value_type" => "string" }
      ]
    end

    it "skips properties without a value" do
      expect(inputs).to eq("fe_cpus" => "2")
    end
  end

  context "with hash properties" do
    let(:properties) { { "fe_cpus" => "16", "admin_password" => "" } }

    it "returns the present values" do
      expect(inputs).to eq("fe_cpus" => "16")
    end
  end

  context "with invalid JSON properties" do
    let(:properties) { ['{"id": "fe_cpus", "value": "8"}', "{not json"] }

    it "skips them" do
      expect(inputs).to eq("fe_cpus" => "8")
    end
  end

  context "with comma-separated dataset_ids" do
    let(:properties) { ['{"id": "dataset_ids", "value": "doi1, doi2,doi3"}'] }

    it "splits them into a list" do
      expect(inputs).to eq("dataset_ids" => %w[doi1 doi2 doi3])
    end
  end

  context "without properties" do
    let(:properties) { [] }

    it "returns no inputs" do
      expect(inputs).to eq({})
    end
  end

  context "with a template declaring a DNS input" do
    let(:template_content) { <<~YAML }
      topology_template:
        inputs:
          jupyter_token:
            type: string
          dns_name:
            type: string
            default: jupyter.test.fedcloud.eu
    YAML
    let(:uuid_dns_pattern) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.vm\.fedcloud\.eu\z/ }

    context "when the user submitted a custom DNS name" do
      let(:properties) do
        ['{"id": "jupyter_token", "value": "secret"}', '{"id": "dns_name", "value": "user.example.com"}']
      end

      it "replaces it with a generated one" do
        expect(inputs).to match("jupyter_token" => "secret", "dns_name" => match(uuid_dns_pattern))
      end
    end

    context "when the order form generated the DNS name" do
      let(:dns_name) { "0b1c2d3e-4f50-6172-8394-a5b6c7d8e9f0.vm.fedcloud.eu" }
      let(:properties) { ["id" => "dns_name", "value" => dns_name] }

      it "deploys it" do
        expect(inputs).to eq("dns_name" => dns_name)
      end
    end

    context "when the generated DNS name is used by another order" do
      let(:dns_name) { "0b1c2d3e-4f50-6172-8394-a5b6c7d8e9f0.vm.fedcloud.eu" }
      let(:properties) { ["id" => "dns_name", "value" => dns_name] }

      before do
        create(
          :project_item,
          properties: [id: "dns_name", label: "DNS name", type: "input", value_type: "string", value: dns_name]
        )
      end

      it "deploys a new DNS name" do
        expect(inputs["dns_name"]).to match(uuid_dns_pattern).and(satisfy { |name| name != dns_name })
      end
    end
  end

  context "with a template declaring kube_public_dns_name" do
    let(:template_content) { "topology_template:\n  inputs:\n    kube_public_dns_name: { type: string }\n" }
    let(:properties) { [] }

    it "generates a DNS name even if the user submitted none" do
      expect(inputs["kube_public_dns_name"]).to match(/\.vm\.fedcloud\.eu\z/)
    end
  end
end
