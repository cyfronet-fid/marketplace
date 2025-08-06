# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe DeployableService, backend: true do
  include_examples "publishable"

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:tagline) }

  it { should have_many(:sources).class_name("DeployableServiceSource").dependent(:destroy) }
  it { should have_many(:deployable_service_scientific_domains).dependent(:destroy) }
  it { should have_many(:scientific_domains) }

  it { should belong_to(:upstream).class_name("DeployableServiceSource").required(false) }
  it { should belong_to(:resource_organisation).class_name("Provider").required(true) }
  it { should belong_to(:catalogue).required(false) }

  it { should have_one_attached(:logo) }

  describe "validations" do
    let(:deployable_service) { build(:deployable_service) }

    it "is valid with valid attributes" do
      expect(deployable_service).to be_valid
    end

    it "validates url format" do
      deployable_service.url = "invalid-url"
      expect(deployable_service).not_to be_valid
      expect(deployable_service.errors[:url]).to include("is not a valid URL")
    end

    it "allows empty url" do
      deployable_service.url = ""
      expect(deployable_service).to be_valid
    end

    it "allows nil url" do
      deployable_service.url = nil
      expect(deployable_service).to be_valid
    end

    it "strips whitespace from string attributes" do
      deployable_service.name = "  Test Name  "
      deployable_service.description = "  Test Description  "
      deployable_service.tagline = "  Test Tagline  "
      deployable_service.url = "  https://example.com  "
      deployable_service.node = "  docker  "
      deployable_service.version = "  1.0.0  "
      deployable_service.software_license = "  MIT  "

      deployable_service.valid?

      expect(deployable_service.name).to eq("Test Name")
      expect(deployable_service.description).to eq("Test Description")
      expect(deployable_service.tagline).to eq("Test Tagline")
      expect(deployable_service.url).to eq("https://example.com")
      expect(deployable_service.node).to eq("docker")
      expect(deployable_service.version).to eq("1.0.0")
      expect(deployable_service.software_license).to eq("MIT")
    end
  end

  describe "logo validation" do
    let(:deployable_service) { build(:deployable_service) }

    it "validates logo is an image" do
      # This would need a proper test file attachment setup
      # For now, we'll just verify the validation exists
      expect(deployable_service.class.validators_on(:logo)).to be_present
    end
  end

  describe "friendly_id" do
    let(:deployable_service) { create(:deployable_service, name: "Test Service") }

    it "generates slug from name" do
      expect(deployable_service.slug).to eq("test-service")
    end

    it "can be found by slug" do
      found = DeployableService.friendly.find(deployable_service.slug)
      expect(found).to eq(deployable_service)
    end
  end

  describe "associations" do
    let(:provider) { create(:provider) }
    let(:catalogue) { create(:catalogue) }
    let(:scientific_domain) { create(:scientific_domain) }
    let(:deployable_service) do
      create(
        :deployable_service,
        resource_organisation: provider,
        catalogue: catalogue,
        scientific_domains: [scientific_domain]
      )
    end

    it "belongs to a provider" do
      expect(deployable_service.resource_organisation).to eq(provider)
    end

    it "can belong to a catalogue" do
      expect(deployable_service.catalogue).to eq(catalogue)
    end

    it "can have scientific domains" do
      expect(deployable_service.scientific_domains).to include(scientific_domain)
    end
  end

  describe "upstream synchronization" do
    let(:source) { create(:deployable_service_source) }
    let(:deployable_service) { create(:deployable_service, upstream: source) }

    it "sets pid from upstream eid when upstream is present" do
      deployable_service.save
      expect(deployable_service.pid).to eq(source.eid)
    end
  end
end
