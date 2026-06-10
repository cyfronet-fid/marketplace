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
        allow_any_instance_of(described_class).to receive(:fetch_template).and_return(template_content)
      end

      subject(:result) { described_class.call(deployable_service) }

      it "creates and returns an offer" do
        expect(result).to be_a(Offer)
        expect(result).to be_persisted
      end

      it "creates offer with correct attributes" do
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

      it "logs successful creation" do
        expect(Rails.logger).to receive(:info).with(
          /Created default offer for DeployableService.*#{deployable_service.name}/
        )
        described_class.call(deployable_service)
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

      before { allow_any_instance_of(described_class).to receive(:fetch_template).and_return(template_content) }

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
        allow_any_instance_of(described_class).to receive(:fetch_template).and_return(template_content)
        # Force offer creation to fail by making service invalid
        allow_any_instance_of(Offer).to receive(:save).and_return(false)
        allow_any_instance_of(Offer).to receive(:errors).and_return(double(full_messages: ["Name can't be blank"]))
      end

      it "returns nil and logs error" do
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
        allow_any_instance_of(described_class).to receive(:fetch_template).and_return(
          "<html><body>GitHub</body></html>"
        )
      end

      it "returns nil and logs the parsing error" do
        allow(Rails.logger).to receive(:error)

        expect(described_class.call(deployable_service)).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Failed to fetch default offer parameters/).at_least(:once)
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
      allow_any_instance_of(described_class).to receive(:fetch_template).and_return(template_content)
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
