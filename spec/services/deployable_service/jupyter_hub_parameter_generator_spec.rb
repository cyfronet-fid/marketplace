# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::JupyterHubParameterGenerator, backend: true do
  describe ".generate_parameters" do
    subject(:parameters) { described_class.generate_parameters }

    it "returns an array of parameters" do
      expect(parameters).to be_an(Array)
      expect(parameters).to all(be_a(Parameter))
    end

    it "generates 10 parameters for JupyterHub DataMount configuration" do
      expect(parameters.size).to eq(10)
    end

    describe "frontend resource parameters" do
      let(:fe_cpus) { parameters.find { |p| p.id == "fe_cpus" } }
      let(:fe_mem) { parameters.find { |p| p.id == "fe_mem" } }
      let(:fe_disk_size) { parameters.find { |p| p.id == "fe_disk_size" } }

      it "creates frontend CPU parameter with correct configuration" do
        expect(fe_cpus).to be_a(Parameter::Select)
        expect(fe_cpus.name).to eq("Frontend CPU Cores")
        expect(fe_cpus.hint).to eq("Number of CPUs for the frontend node")
        expect(fe_cpus.values).to eq([4])
        expect(fe_cpus.value_type).to eq("integer")
        expect(fe_cpus.mode).to eq("dropdown")
      end

      it "creates frontend memory parameter with correct configuration" do
        expect(fe_mem).to be_a(Parameter::Select)
        expect(fe_mem.name).to eq("Frontend Memory")
        expect(fe_mem.hint).to eq("Amount of memory for the frontend node")
        expect(fe_mem.values).to eq(["4 GB", "8 GB", "16 GB", "32 GB"])
        expect(fe_mem.value_type).to eq("string")
      end

      it "creates frontend disk parameter with correct configuration" do
        expect(fe_disk_size).to be_a(Parameter::Select)
        expect(fe_disk_size.name).to eq("Frontend Disk Size")
        expect(fe_disk_size.values).to eq(["100 GiB", "200 GiB", "500 GiB"])
      end
    end

    describe "worker node parameters" do
      let(:wn_num) { parameters.find { |p| p.id == "wn_num" } }
      let(:wn_cpus) { parameters.find { |p| p.id == "wn_cpus" } }
      let(:wn_mem) { parameters.find { |p| p.id == "wn_mem" } }
      let(:wn_disk_size) { parameters.find { |p| p.id == "wn_disk_size" } }

      it "creates worker node count parameter" do
        expect(wn_num).to be_a(Parameter::Select)
        expect(wn_num.name).to eq("Number of Worker Nodes")
        expect(wn_num.values).to eq([1, 2, 3, 4, 5])
        expect(wn_num.value_type).to eq("integer")
      end

      it "creates worker node CPU parameter" do
        expect(wn_cpus).to be_a(Parameter::Select)
        expect(wn_cpus.name).to eq("Worker Node CPUs")
        expect(wn_cpus.values).to eq([2, 4, 8, 16])
      end

      it "creates worker node memory parameter" do
        expect(wn_mem).to be_a(Parameter::Select)
        expect(wn_mem.values).to eq(["8 GB", "16 GB", "32 GB"])
      end

      it "creates worker node disk parameter" do
        expect(wn_disk_size).to be_a(Parameter::Select)
        expect(wn_disk_size.values).to eq(["50 GiB", "100 GiB", "200 GiB"])
      end
    end

    describe "configuration parameters" do
      let(:dns_name) { parameters.find { |p| p.id == "kube_public_dns_name" } }
      let(:admin_password) { parameters.find { |p| p.id == "admin_password" } }
      let(:dataset_ids) { parameters.find { |p| p.id == "dataset_ids" } }

      it "creates DNS name parameter" do
        expect(dns_name).to be_a(Parameter::Input)
        expect(dns_name.name).to eq("Public DNS Hostname")
        expect(dns_name.hint).to eq("DNS name for JupyterHub access")
        expect(dns_name.value_type).to eq("string")
      end

      it "creates admin password parameter" do
        expect(admin_password).to be_a(Parameter::Input)
        expect(admin_password.name).to eq("JupyterHub Admin Password")
        expect(admin_password.value_type).to eq("string")
      end

      it "creates dataset IDs parameter" do
        expect(dataset_ids).to be_a(Parameter::Select)
        expect(dataset_ids.name).to eq("Dataset DOI")
        expect(dataset_ids.hint).to eq("Dataset DOIs to mount")
        expect(dataset_ids.value_type).to eq("string")
        expect(dataset_ids.mode).to eq("dropdown")
        expect(dataset_ids.values).to eq(
          %w[
            10.48372/84a70617-3606-499d-bbe6-2b52ccf33392
            10.48372/29290d64-a840-4ffc-accf-5bf68deef233
            10.48372/285eff33-55de-4d0e-8b7f-c995dc80478e
            10.48372/98914415-765c-4650-b272-b16793231e8a
            10.48372/30d8844e-1774-4c63-89c4-4d858f88317d
          ]
        )
      end
    end

    describe "parameter validation" do
      it "generates valid parameters" do
        parameters.each do |param|
          expect(param).to be_valid, "Parameter #{param.id} should be valid: #{param.errors.full_messages}"
        end
      end

      it "generates parameters with unique IDs" do
        parameter_ids = parameters.map(&:id)
        expect(parameter_ids).to eq(parameter_ids.uniq)
      end

      it "generates parameters with required attributes" do
        parameters.each do |param|
          expect(param.id).to be_present
          expect(param.name).to be_present
          expect(param.hint).to be_present
        end
      end
    end

    describe "parameter serialization" do
      it "can serialize and deserialize parameters" do
        parameters.each do |param|
          serialized = param.dump
          expect(serialized).to be_a(Hash)
          expect(serialized["id"]).to eq(param.id)
          expect(serialized["type"]).to eq(param.type)
          expect(serialized["label"]).to eq(param.name)
          expect(serialized["description"]).to eq(param.hint)
        end
      end
    end
  end
end
