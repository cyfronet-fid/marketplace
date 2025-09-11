# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe DeployableService, backend: true do
  include_examples "publishable"

  # Explicit validation tests instead of shoulda-matchers due to duck-typing conflicts
  describe "validations" do
    it "validates presence of name" do
      service = build(:deployable_service, name: nil)
      expect(service).not_to be_valid
      expect(service.errors[:name]).to include("can't be blank")
    end

    it "validates presence of description" do
      service = build(:deployable_service, description: nil)
      expect(service).not_to be_valid
      expect(service.errors[:description]).to include("can't be blank")
    end

    it "validates presence of tagline" do
      service = build(:deployable_service, tagline: nil)
      expect(service).not_to be_valid
      expect(service.errors[:tagline]).to include("can't be blank")
    end
  end

  it { should have_many(:sources).class_name("DeployableServiceSource").dependent(:destroy) }
  it { should have_many(:deployable_service_scientific_domains).dependent(:destroy) }
  it { should have_many(:scientific_domains) }
  it { should have_many(:offers).dependent(:destroy) }

  # Explicit association tests instead of shoulda-matchers due to duck-typing conflicts
  describe "associations" do
    it "belongs to upstream" do
      expect(described_class.reflect_on_association(:upstream).class_name).to eq("DeployableServiceSource")
      expect(described_class.reflect_on_association(:upstream).options[:optional]).to be true
    end

    it "belongs to resource_organisation" do
      expect(described_class.reflect_on_association(:resource_organisation).class_name).to eq("Provider")
      expect(described_class.reflect_on_association(:resource_organisation).options[:optional]).to be false
    end

    it "belongs to catalogue" do
      expect(described_class.reflect_on_association(:catalogue).options[:optional]).to be true
    end
  end

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

  describe "JupyterHub template detection and offers" do
    let(:provider) { create(:provider) }
    let(:service_category) { create(:service_category) }

    describe "#jupyterhub_datamount_template?" do
      it "returns true for GitHub JupyterHub datamount template URL" do
        ds =
          build(
            :deployable_service,
            url: "https://github.com/grycap/tosca/blob/eosc_beyond/templates/jupyterhub_datamount.yml"
          )
        expect(ds.jupyterhub_datamount_template?).to be true
      end

      it "returns true for any URL containing jupyterhub_datamount.yml" do
        ds = build(:deployable_service, url: "https://example.com/templates/jupyterhub_datamount.yml")
        expect(ds.jupyterhub_datamount_template?).to be true
      end

      it "returns true for names containing jupyterhub" do
        ds = build(:deployable_service, name: "JupyterHub Data Service", url: "https://example.com")
        expect(ds.jupyterhub_datamount_template?).to be true
      end

      it "returns false for non-JupyterHub services" do
        ds = build(:deployable_service, name: "Docker Service", url: "https://example.com/docker.yml")
        expect(ds.jupyterhub_datamount_template?).to be false
      end

      it "handles nil URL gracefully" do
        ds = build(:deployable_service, name: "Test Service", url: nil)
        expect(ds.jupyterhub_datamount_template?).to be false
      end
    end

    describe "offers relationship" do
      let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }

      it "can have multiple offers" do
        offer1 =
          create(
            :offer,
            service: nil,
            deployable_service: deployable_service,
            name: "Config 1",
            offer_category: service_category
          )
        offer2 =
          create(
            :offer,
            service: nil,
            deployable_service: deployable_service,
            name: "Config 2",
            offer_category: service_category
          )

        expect(deployable_service.offers).to include(offer1, offer2)
        expect(deployable_service.offers.count).to eq(2)
      end

      it "destroys associated offers when deployable service is destroyed" do
        offer = create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category)
        offer_id = offer.id

        deployable_service.destroy

        expect { Offer.find(offer_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "auto-offer creation workflow" do
      let(:compute_category) { create(:service_category, eid: "service_category-compute", name: "Compute") }

      before { compute_category } # Ensure category exists

      context "when creating a JupyterHub deployable service" do
        let(:jupyter_service_attrs) do
          {
            name: "Test JupyterHub DataMount",
            description: "A test JupyterHub service for data mounting",
            tagline: "Mount your data in JupyterHub",
            url: "https://github.com/grycap/tosca/blob/eosc_beyond/templates/jupyterhub_datamount.yml",
            resource_organisation: provider
          }
        end

        it "automatically creates an offer after creation" do
          expect { create(:deployable_service, jupyter_service_attrs) }.to change { Offer.count }.by(1)
        end

        it "creates offer with correct deployable service association" do
          ds = create(:deployable_service, jupyter_service_attrs)
          offer = ds.offers.first

          expect(offer).to be_present
          expect(offer.deployable_service).to eq(ds)
          expect(offer.service).to be_nil
        end

        it "creates offer with JupyterHub-specific parameters" do
          ds = create(:deployable_service, jupyter_service_attrs)
          offer = ds.offers.first

          expect(offer.parameters.size).to eq(10)
          parameter_ids = offer.parameters.map(&:id)
          expect(parameter_ids).to include("fe_cpus", "wn_num", "admin_password", "dataset_ids")
        end

        it "creates published, internal offer ready for ordering" do
          ds = create(:deployable_service, jupyter_service_attrs)
          offer = ds.offers.first

          expect(offer.status).to eq("published")
          expect(offer.order_type).to eq("order_required")
          expect(offer.internal).to be(true)
          expect(offer.offer_category).to eq(compute_category)
        end
      end

      context "when creating non-JupyterHub deployable service" do
        let(:non_jupyter_attrs) do
          {
            name: "Docker Container Service",
            description: "A generic container service",
            tagline: "Run containers",
            url: "https://example.com/docker-compose.yml",
            resource_organisation: provider
          }
        end

        it "does not create an offer" do
          expect { create(:deployable_service, non_jupyter_attrs) }.not_to change { Offer.count }
        end
      end

      context "when compute service category is missing" do
        let(:jupyter_attrs) do
          {
            name: "JupyterHub Service",
            description: "Test service",
            tagline: "Testing",
            url: "https://example.com/jupyterhub_datamount.yml",
            resource_organisation: provider
          }
        end

        before { compute_category.destroy }

        it "does not create an offer and logs error" do
          expect(Rails.logger).to receive(:error).with(/Could not find 'service_category-compute'/)

          expect { create(:deployable_service, jupyter_attrs) }.not_to change { Offer.count }
        end
      end
    end
  end

  describe "Service-like duck-typing methods" do
    let(:provider) { create(:provider) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }

    describe "#service_categories" do
      it "returns empty array" do
        expect(deployable_service.service_categories).to eq([])
      end
    end

    describe "#categories" do
      it "returns empty array" do
        expect(deployable_service.categories).to eq([])
      end
    end

    describe "#target_users" do
      it "returns empty array" do
        expect(deployable_service.target_users).to eq([])
      end
    end

    describe "#access_types" do
      it "returns empty array" do
        expect(deployable_service.access_types).to eq([])
      end
    end

    describe "#access_modes" do
      it "returns empty array" do
        expect(deployable_service.access_modes).to eq([])
      end
    end

    describe "#geographical_availabilities" do
      it "returns empty array" do
        expect(deployable_service.geographical_availabilities).to eq([])
      end
    end

    describe "#language_availability" do
      it "returns empty array" do
        expect(deployable_service.language_availability).to eq([])
      end
    end

    describe "#providers" do
      it "returns array with resource_organisation" do
        expect(deployable_service.providers).to eq([provider])
      end

      it "returns empty array when resource_organisation is nil" do
        deployable_service.resource_organisation = nil
        expect(deployable_service.providers).to eq([])
      end
    end

    describe "#horizontal" do
      it "returns false" do
        expect(deployable_service.horizontal).to be false
      end
    end

    describe "#thematic" do
      it "returns false" do
        expect(deployable_service.thematic).to be false
      end
    end

    describe "#order_type" do
      it "returns 'order_required'" do
        expect(deployable_service.order_type).to eq("order_required")
      end
    end

    describe "#order_url" do
      it "returns the deployable service url" do
        expect(deployable_service.order_url).to eq(deployable_service.url)
      end
    end

    describe "#terms_of_use_url" do
      it "returns nil" do
        expect(deployable_service.terms_of_use_url).to be_nil
      end
    end

    describe "method_missing behavior" do
      it "handles boolean methods with false return" do
        expect(deployable_service.non_existent_method?).to be false
      end

      it "handles count methods with 0 return" do
        expect(deployable_service.non_existent_count).to eq(0)
      end

      it "handles plural methods by returning empty collection" do
        # This should return an empty collection for plural methods
        expect { deployable_service.non_existent_items }.not_to raise_error
        expect(deployable_service.non_existent_items).to eq([])
      end

      it "raises NoMethodError for unhandled methods" do
        expect { deployable_service.completely_unknown_method }.to raise_error(NoMethodError)
      end
    end

    describe "#offers_count" do
      it "returns 0 when no offers" do
        expect(deployable_service.offers_count).to eq(0)
      end

      it "returns correct count when offers exist" do
        create(:offer, deployable_service: deployable_service, service: nil, offer_category: create(:service_category))
        create(:offer, deployable_service: deployable_service, service: nil, offer_category: create(:service_category))
        expect(deployable_service.offers_count).to eq(2)
      end
    end

    describe "#bundles_count" do
      it "returns 0" do
        expect(deployable_service.bundles_count).to eq(0)
      end
    end

    describe "#store_analytics" do
      it "does not raise error" do
        expect { deployable_service.store_analytics }.not_to raise_error
      end
    end

    describe "#monitoring_status" do
      it "returns nil" do
        expect(deployable_service.monitoring_status).to be_nil
      end
    end

    describe "#monitoring_status=" do
      it "accepts value without error" do
        expect { deployable_service.monitoring_status = "active" }.not_to raise_error
        expect(deployable_service.monitoring_status).to be_nil
      end
    end

    describe "#main_contact" do
      it "returns nil" do
        expect(deployable_service.main_contact).to be_nil
      end
    end

    describe "#public_contacts" do
      it "returns empty array" do
        expect(deployable_service.public_contacts).to eq([])
      end
    end
  end

  describe "OfferScopeExtensions" do
    let(:provider) { create(:provider) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }
    let(:service_category) { create(:service_category) }

    before do
      # Create published and draft offers
      create(
        :offer,
        deployable_service: deployable_service,
        service: nil,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
      create(
        :offer,
        deployable_service: deployable_service,
        service: nil,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
      create(
        :offer,
        deployable_service: deployable_service,
        service: nil,
        status: :draft,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    describe "#offers" do
      it "returns relation extended with OfferScopeExtensions" do
        offers_relation = deployable_service.offers
        expect(offers_relation).to respond_to(:inclusive)
        expect(offers_relation).to respond_to(:accessible)
        expect(offers_relation).to respond_to(:active)
      end
    end

    describe "extended scopes" do
      describe "#inclusive" do
        it "returns published offers for published DeployableService" do
          inclusive_offers = deployable_service.offers.inclusive
          expect(inclusive_offers.count).to eq(2)
          expect(inclusive_offers.all?(&:published?)).to be true
        end

        it "returns empty for unpublished DeployableService" do
          deployable_service.update(status: :draft)
          inclusive_offers = deployable_service.offers.inclusive
          expect(inclusive_offers.count).to eq(0)
        end
      end

      describe "#accessible" do
        it "returns published offers for published DeployableService" do
          accessible_offers = deployable_service.offers.accessible
          expect(accessible_offers.count).to eq(2)
          expect(accessible_offers.all?(&:published?)).to be true
        end

        it "returns empty for unpublished DeployableService" do
          deployable_service.update(status: :draft)
          accessible_offers = deployable_service.offers.accessible
          expect(accessible_offers.count).to eq(0)
        end
      end

      describe "#active" do
        before do
          # Create active offer (published, not bundle_exclusive, available)
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            limited_availability: false,
            offer_category: service_category
          )
          # Create bundle exclusive offer
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: true,
            limited_availability: false,
            offer_category: service_category
          )
          # Create limited availability offer with 0 count
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            limited_availability: true,
            availability_count: 0,
            offer_category: service_category
          )
        end

        it "returns only active offers" do
          active_offers = deployable_service.offers.active
          expect(active_offers.count).to eq(3) # 2 original + 1 new active
          active_offers.each do |offer|
            expect(offer.published?).to be true
            expect(offer.bundle_exclusive).to be false
            expect(offer.limited_availability? ? offer.availability_count > 0 : true).to be true
          end
        end
      end
    end
  end
end
