# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Offer parent service compatibility", type: :model do
  # This spec ensures that Offer works correctly with both Service
  # and DeployableService as parent. This is critical for the polymorphic
  # refactoring - these tests should pass before and after.

  let(:provider) { create(:provider) }
  let(:service_category) { create(:service_category) }

  describe "Offer with Service parent" do
    # Create service without factory-generated offers
    let(:service) { create(:service, resource_organisation: provider, status: :published, offers: []) }
    let(:offer) do
      create(
        :offer,
        service: service,
        deployable_service: nil,
        offer_category: service_category,
        status: :published,
        bundle_exclusive: false
      )
    end

    describe "parent_service accessor" do
      it "returns the service" do
        expect(offer.parent_service).to eq(service)
      end

      it "returns service via service accessor" do
        expect(offer.service).to eq(service)
      end

      it "returns nil via deployable_service accessor" do
        expect(offer.deployable_service).to be_nil
      end
    end

    describe "association from parent" do
      it "is included in service.offers" do
        offer # trigger creation
        service.reload
        expect(service.offers).to include(offer)
      end

      it "increments service offers_count" do
        offer # trigger creation
        expect(service.reload.offers_count).to be >= 1
      end
    end

    describe "scopes" do
      it "is included in Offer.inclusive" do
        expect(Offer.inclusive).to include(offer)
      end

      it "is included in Offer.accessible" do
        expect(Offer.accessible).to include(offer)
      end

      it "is excluded from inclusive when service is draft" do
        service.update!(status: :draft)
        expect(Offer.inclusive).not_to include(offer)
      end

      it "is excluded from inclusive when bundle_exclusive" do
        offer.update!(bundle_exclusive: true)
        expect(Offer.inclusive).not_to include(offer)
      end
    end

    describe "order_type validation" do
      it "validates order_type matches service" do
        # First published offer should match service order_type
        expect(offer).to be_valid
      end
    end
  end

  describe "Offer with DeployableService parent" do
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }
    let(:offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published,
        bundle_exclusive: false
      )
    end

    describe "parent_service accessor" do
      it "returns the deployable_service" do
        expect(offer.parent_service).to eq(deployable_service)
      end

      it "returns nil via service accessor" do
        expect(offer.service).to be_nil
      end

      it "returns deployable_service via deployable_service accessor" do
        expect(offer.deployable_service).to eq(deployable_service)
      end
    end

    describe "association from parent" do
      it "is included in deployable_service.offers" do
        expect(deployable_service.offers).to include(offer)
      end
    end

    describe "scopes" do
      it "is included in Offer.inclusive" do
        expect(Offer.inclusive).to include(offer)
      end

      it "is included in Offer.accessible" do
        expect(Offer.accessible).to include(offer)
      end

      it "is excluded from inclusive when deployable_service is draft" do
        deployable_service.update!(status: :draft)
        expect(Offer.inclusive).not_to include(offer)
      end
    end
  end

  describe "validation: orderable must be present" do
    let(:service) { create(:service, resource_organisation: provider) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }

    it "is invalid without any orderable" do
      offer = build(:offer, service: nil, deployable_service: nil, offer_category: service_category)
      expect(offer).not_to be_valid
      expect(offer.errors[:base]).to include("Must belong to either service or deployable service")
    end

    it "is valid with service as orderable" do
      offer = build(:offer, service: service, offer_category: service_category)
      expect(offer).to be_valid
      expect(offer.orderable).to eq(service)
    end

    it "is valid with deployable_service as orderable" do
      offer = build(:offer, deployable_service: deployable_service, offer_category: service_category)
      expect(offer).to be_valid
      expect(offer.orderable).to eq(deployable_service)
    end

    it "uses service when both are provided (service takes precedence)" do
      # With polymorphic association, only one orderable can be set
      # Factory gives precedence to service when both are provided
      offer = build(:offer, service: service, deployable_service: deployable_service, offer_category: service_category)
      expect(offer).to be_valid
      expect(offer.orderable).to eq(service)
    end
  end

  describe "ProjectItem creation" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }

    context "with Service offer" do
      let(:service) { create(:service, resource_organisation: provider, status: :published) }
      let(:offer) do
        create(:offer, service: service, deployable_service: nil, offer_category: service_category, status: :published)
      end

      it "creates project item successfully" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item).to be_persisted
      end

      it "project_item.service returns the service" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item.service).to eq(service)
      end

      it "project_item.offer.parent_service returns the service" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item.offer.parent_service).to eq(service)
      end
    end

    context "with DeployableService offer" do
      let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }
      let(:offer) do
        create(
          :offer,
          service: nil,
          deployable_service: deployable_service,
          offer_category: service_category,
          status: :published
        )
      end

      it "creates project item successfully" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item).to be_persisted
      end

      it "project_item.service returns the deployable_service" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item.service).to eq(deployable_service)
      end

      it "project_item.offer.parent_service returns the deployable_service" do
        project_item = create(:project_item, offer: offer, project: project)
        expect(project_item.offer.parent_service).to eq(deployable_service)
      end
    end
  end

  describe "mixed offers in same query" do
    let(:service) { create(:service, resource_organisation: provider, status: :published) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    let!(:service_offer) do
      create(
        :offer,
        service: service,
        deployable_service: nil,
        offer_category: service_category,
        status: :published,
        bundle_exclusive: false
      )
    end

    let!(:ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published,
        bundle_exclusive: false
      )
    end

    it "Offer.inclusive includes both types" do
      inclusive = Offer.inclusive
      expect(inclusive).to include(service_offer)
      expect(inclusive).to include(ds_offer)
    end

    it "Offer.accessible includes both types" do
      accessible = Offer.accessible
      expect(accessible).to include(service_offer)
      expect(accessible).to include(ds_offer)
    end

    it "each offer has correct parent_service" do
      expect(service_offer.parent_service).to eq(service)
      expect(ds_offer.parent_service).to eq(deployable_service)
    end

    it "Offer.all includes both types" do
      expect(Offer.all).to include(service_offer)
      expect(Offer.all).to include(ds_offer)
    end
  end

  describe "counter cache behavior" do
    context "for Service" do
      let(:service) { create(:service, resource_organisation: provider, status: :published, offers_count: 0) }

      it "increments offers_count when published offer created" do
        expect do
          create(
            :offer,
            service: service,
            deployable_service: nil,
            offer_category: service_category,
            status: :published
          )
        end.to change { service.reload.offers_count }.by(1)
      end
    end

    context "for DeployableService" do
      let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

      it "offers_count reflects actual offers" do
        create(
          :offer,
          service: nil,
          deployable_service: deployable_service,
          offer_category: service_category,
          status: :published
        )
        # DeployableService calculates offers_count dynamically
        expect(deployable_service.offers_count).to eq(1)
      end
    end
  end

  describe "policy compatibility" do
    let(:user) { create(:user) }
    let(:service) { create(:service, resource_organisation: provider, status: :published) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    let(:service_offer) do
      create(:offer, service: service, deployable_service: nil, offer_category: service_category, status: :published)
    end

    let(:ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        offer_category: service_category,
        status: :published
      )
    end

    it "OfferPolicy works with service offer" do
      expect { Pundit.policy(user, service_offer) }.not_to raise_error
    end

    it "OfferPolicy works with deployable_service offer" do
      expect { Pundit.policy(user, ds_offer) }.not_to raise_error
    end
  end
end
