# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::CreateDefaultOffer, backend: true do
  let(:provider) { create(:provider) }
  let(:compute_category) { create(:service_category, eid: "service_category-compute", name: "Compute") }
  let(:template_content) { <<~YAML }
      tosca_definitions_version: tosca_simple_yaml_1_2
      topology_template:
        inputs:
          fe_cpus:
            type: integer
            description: Number of CPUs for the frontend node
            constraints:
              - valid_values: [2, 4, 8]
          admin_password:
            type: string
            description: Password for JupyterHub administrator user
          dataset_ids:
            type: list
            description: Dataset DOIs to mount
    YAML

  describe "#call" do
    context "with a deployable service template URL" do
      let(:deployable_service) do
        create(
          :deployable_service,
          name: "JupyterHub DataMount Service",
          url: "https://github.com/grycap/tosca/blob/eosc_beyond/templates/jupyterhub_datamount.yml",
          resource_organisation: provider
        )
      end

      before do
        compute_category
        allow(DeployableService::FetchTemplate).to receive(:call).and_return(template_content)
      end

      subject(:result) { described_class.call(deployable_service) }

      it "creates and returns an offer" do
        expect(result).to be_a(Offer)
        expect(result).to be_persisted
      end

      xit "creates offer with correct attributes" do # needs fix
        expect(result.deployable_service).to eq(deployable_service)
        expect(result.name).to eq("Deploy #{deployable_service.name}")
        expect(result.description).to eq(
          "Deploy #{deployable_service.name} with JupyterHub and DataMount configuration"
        )
        expect(result.status).to eq("published")
        expect(result.order_type).to eq("order_required")
        expect(result.internal).to be(true)
        expect(result.voucherable).to be(false)
        expect(result.offer_category).to eq(compute_category)
      end

      it "creates offer parameters from the TOSCA template inputs" do
        expect(result.parameters.size).to eq(3)
        expect(result.parameters).to all(be_a(Parameter))
      end

      it "includes expected parameter IDs" do
        parameter_ids = result.parameters.map(&:id)

        expect(parameter_ids).to match_array(%w[fe_cpus admin_password dataset_ids])
      end

      it "maps TOSCA valid_values to select parameters" do
        parameter = result.parameters.find { |p| p.id == "fe_cpus" }

        expect(parameter).to be_a(Parameter::Select)
        expect(parameter.value_type).to eq("integer")
        expect(parameter.values).to eq([2, 4, 8])
      end

      it "marks password-like inputs as sensitive" do
        parameter = result.parameters.find { |p| p.id == "admin_password" }

        expect(parameter).to be_a(Parameter::Input)
        expect(parameter.sensitive).to be(true)
      end

      it "creates a valid offer" do
        expect(result).to be_valid
      end

      it "associates offer with deployable service" do
        expect(result.deployable_service).to eq(deployable_service)
        expect(deployable_service.reload.offers).to include(result)
      end

      xit "logs successful creation" do # needs fix
        expect(Rails.logger).to receive(:info).with(
          /Created default offer for DeployableService.*#{deployable_service.name}/
        )
        described_class.call(deployable_service)
      end

      it "updates an existing default offer instead of creating a duplicate" do
        existing_offer = result
        updated_template = <<~YAML
          tosca_definitions_version: tosca_simple_yaml_1_2
          topology_template:
            inputs:
              memory:
                type: integer
                description: Memory size
        YAML

        allow(DeployableService::FetchTemplate).to receive(:call).and_return(updated_template)

        expect { described_class.call(deployable_service) }.not_to change { deployable_service.offers.count }
        expect(existing_offer.reload.parameters.map(&:id)).to eq(["memory"])
      end
    end

    context "with TOSCA input defaults" do
      let(:template_content) { <<~YAML }
        tosca_definitions_version: tosca_simple_yaml_1_2
        topology_template:
          inputs:
            image:
              type: string
              default: ubuntu-22.04
            wn_num:
              type: integer
              default: "3"
            wn_cpus:
              type: integer
              default: "010"
            mem_size:
              type: scalar-unit.size
              default: 4 GiB
            fe_cpus:
              type: integer
              default: 4
              constraints:
                - valid_values: [2, 4, 8]
            fe_mem:
              type: string
              default: 64 GB
              constraints:
                - valid_values: ["4 GB", "8 GB"]
            notebook_url:
              type: string
            admin_password:
              type: string
              default: changeme
            jupyter_token:
              type: string
              default: abc123
            dns_name:
              type: string
              default: jupyter.example.com
            dataset_ids:
              type: list
              default: []
            enable_gpu:
              type: boolean
              default: true
      YAML
      let(:deployable_service) do
        create(:deployable_service, url: "https://example.com/template.yml", resource_organisation: provider)
      end
      let(:defaults) { described_class.call(deployable_service).parameters.to_h { |p| [p.id, p.default_value] } }

      before do
        compute_category
        allow(DeployableService::FetchTemplate).to receive(:call).and_return(template_content)
      end

      it "pre-fills string inputs with their default" do
        expect(defaults["image"]).to eq("ubuntu-22.04")
      end

      it "casts integer defaults to integers" do
        expect(defaults["wn_num"]).to eq(3)
      end

      it "parses integer defaults as decimal" do
        expect(defaults["wn_cpus"]).to eq(10)
      end

      it "pre-fills scalar-unit inputs with their default" do
        expect(defaults["mem_size"]).to eq("4 GiB")
      end

      it "pre-selects a select default that is one of the valid values" do
        expect(defaults["fe_cpus"]).to eq(4)
      end

      it "does not pre-select a select default outside the valid values" do
        expect(defaults["fe_mem"]).to be_nil
      end

      it "leaves inputs without a default empty" do
        expect(defaults["notebook_url"]).to be_nil
      end

      it "never pre-fills sensitive inputs" do
        expect(defaults.values_at("admin_password", "jupyter_token")).to all(be_nil)
      end

      it "does not pre-fill generated DNS inputs" do
        expect(defaults["dns_name"]).to be_nil
      end

      it "does not pre-fill inputs of other TOSCA types" do
        expect(defaults.values_at("dataset_ids", "enable_gpu")).to all(be_nil)
      end

      it "persists defaults with the offer parameters" do
        offer = described_class.call(deployable_service)

        expect(offer.reload.parameters.find { |p| p.id == "wn_num" }.default_value).to eq(3)
      end
    end

    context "when compute service category is missing" do
      let(:deployable_service) do
        create(
          :deployable_service,
          name: "JupyterHub Service",
          url: "https://example.com/jupyterhub_datamount.yml",
          resource_organisation: provider
        )
      end

      before { allow(DeployableService::FetchTemplate).to receive(:call).and_return(template_content) }

      it "returns nil and logs error" do
        allow(Rails.logger).to receive(:error)
        result = described_class.call(deployable_service)
        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Could not find 'service_category-compute'/).at_least(:once)
      end
    end

    context "when offer creation fails" do
      let(:deployable_service) do
        create(
          :deployable_service,
          name: "JupyterHub Service",
          url: "https://example.com/jupyterhub_datamount.yml",
          resource_organisation: provider
        )
      end

      before do
        compute_category
        allow(DeployableService::FetchTemplate).to receive(:call).and_return(template_content)
        # Force offer creation to fail by making service invalid
        allow_any_instance_of(Offer).to receive(:save).and_return(false)
        allow_any_instance_of(Offer).to receive(:errors).and_return(double(full_messages: ["Name can't be blank"]))
      end

      xit "returns nil and logs error" do # needs fix
        allow(Rails.logger).to receive(:error)
        result = described_class.call(deployable_service)
        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).with(
          /Failed to create default offer.*Name can't be blank/
        ).at_least(:once)
      end
    end

    context "when URL does not return valid YAML" do
      let(:deployable_service) do
        build(
          :deployable_service,
          name: "Docker JupyterHub",
          url: "https://github.com/jupyterhub/jupyterhub-docker",
          resource_organisation: provider
        )
      end

      before do
        compute_category
        allow(DeployableService::FetchTemplate).to receive(:call).and_return(
          "<html><body>GitHub</body></html>"
        )
      end

      it "returns nil and logs the parsing error" do
        allow(Rails.logger).to receive(:error)

        expect(described_class.call(deployable_service)).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Failed to fetch default offer parameters/).at_least(:once)
      end
    end

    context "when the template cannot be fetched" do
      let(:deployable_service) do
        build(:deployable_service, url: "https://example.com/template.yml", resource_organisation: provider)
      end

      before do
        compute_category
        allow(DeployableService::FetchTemplate).to receive(:call).and_raise(Faraday::ConnectionFailed, "refused")
        allow(Rails.error).to receive(:report)
      end

      it "raises the error in development and test" do
        expect { described_class.call(deployable_service) }.to raise_error(Faraday::ConnectionFailed, "refused")
      end

      it "returns nil in production" do
        allow(Rails.env).to receive(:local?).and_return(false)

        expect(described_class.call(deployable_service)).to be_nil
      end

      it "reports the error with the template URL in production" do
        allow(Rails.env).to receive(:local?).and_return(false)
        described_class.call(deployable_service)

        expect(Rails.error).to have_received(:report)
          .with(be_a(Faraday::ConnectionFailed), context: { url: "https://example.com/template.yml" })
      end
    end

    context "when the template URL resolves to an internal address" do
      let(:deployable_service) do
        build(:deployable_service, url: "https://internal.example/template.yml", resource_organisation: provider)
      end

      before do
        compute_category
        allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.tcp("10.0.0.5", 443)])
      end

      it "raises before requesting the template" do
        expect { described_class.call(deployable_service) }.to raise_error(
          HttpMiddleware::SsrfProtection::BlockedRequestError
        )
      end
    end
  end

  describe "integration with DeployableService" do
    let(:deployable_service) do
      build(
        :deployable_service,
        name: "Test JupyterHub",
        url: "https://example.com/jupyterhub_datamount.yml",
        resource_organisation: provider
      )
    end

    before do
      compute_category
      allow(DeployableService::FetchTemplate).to receive(:call).and_return(template_content)
    end

    it "can be called through service object method" do
      # Simulate the callback behavior without triggering it
      allow(deployable_service).to receive(:jupyterhub_datamount_template?).and_return(true)

      result = described_class.call(deployable_service)
      expect(result).to be_a(Offer)
      expect(result.deployable_service).to eq(deployable_service)
    end
  end
end
