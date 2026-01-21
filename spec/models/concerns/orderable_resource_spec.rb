# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderableResource, type: :model do
  # Test the concern through DeployableService which includes it
  let(:provider) { create(:provider) }
  let(:catalogue) { create(:catalogue) }

  describe "included scopes" do
    let!(:published_ds) do
      create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :published)
    end
    let!(:draft_ds) do
      create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :draft)
    end
    let!(:suspended_ds) do
      create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :suspended)
    end
    let!(:deleted_ds) do
      create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :deleted)
    end

    describe ".visible" do
      it "includes published and unverified resources" do
        expect(DeployableService.visible).to include(published_ds)
      end

      it "excludes draft resources" do
        expect(DeployableService.visible).not_to include(draft_ds)
      end

      it "excludes deleted resources" do
        expect(DeployableService.visible).not_to include(deleted_ds)
      end
    end

    describe ".active" do
      it "includes published resources" do
        expect(DeployableService.active).to include(published_ds)
      end

      it "excludes draft resources" do
        expect(DeployableService.active).not_to include(draft_ds)
      end

      it "excludes suspended resources" do
        expect(DeployableService.active).not_to include(suspended_ds)
      end

      it "excludes deleted resources" do
        expect(DeployableService.active).not_to include(deleted_ds)
      end
    end
  end

  describe "shared method implementations" do
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    describe "#offers?" do
      context "when resource has offers" do
        let(:service_category) { create(:service_category) }

        before do
          create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category)
        end

        it "returns true" do
          expect(deployable_service.reload.offers?).to be true
        end
      end

      context "when resource has no offers" do
        it "returns false" do
          expect(deployable_service.offers?).to be false
        end
      end
    end

    describe "#bundles?" do
      context "when resource has no bundles" do
        it "returns false" do
          expect(deployable_service.bundles?).to be false
        end
      end
    end

    describe "#suspended?" do
      it "returns true when status is suspended" do
        deployable_service.status = "suspended"
        expect(deployable_service.suspended?).to be true
      end

      it "returns false when status is not suspended" do
        expect(deployable_service.suspended?).to be false
      end
    end

    describe "#deleted?" do
      it "returns true when status is deleted" do
        deployable_service.status = "deleted"
        expect(deployable_service.deleted?).to be true
      end

      it "returns false when status is not deleted" do
        expect(deployable_service.deleted?).to be false
      end
    end

    describe "#draft?" do
      it "returns true when status is draft" do
        deployable_service.status = "draft"
        expect(deployable_service.draft?).to be true
      end

      it "returns false when status is not draft" do
        expect(deployable_service.draft?).to be false
      end
    end

    describe "#published?" do
      it "returns true when status is published" do
        expect(deployable_service.published?).to be true
      end

      it "returns false when status is not published" do
        deployable_service.status = "draft"
        expect(deployable_service.published?).to be false
      end
    end
  end

  describe "search link methods" do
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    context "when external search is enabled" do
      let(:search_base_url) { "https://search.example.com" }

      before do
        allow(Mp::Application.config).to receive(:enable_external_search).and_return(true)
        allow(Mp::Application.config).to receive(:search_service_base_url).and_return(search_base_url)
      end

      describe "#organisation_search_link" do
        it "returns external search URL with resource_organisation filter" do
          result = deployable_service.organisation_search_link("Test Provider")
          expect(result).to eq("#{search_base_url}/search/service?q=*&fq=resource_organisation:(%22Test Provider%22)")
        end
      end

      describe "#node_search_link" do
        it "returns external search URL with node filter" do
          result = deployable_service.node_search_link("Test Node")
          expect(result).to eq("#{search_base_url}/search/service?q=*&fq=node:(%22Test Node%22)")
        end
      end

      describe "#provider_search_link" do
        it "returns external search URL with providers filter" do
          result = deployable_service.provider_search_link("Test Provider")
          expect(result).to eq("#{search_base_url}/search/service?q=*&fq=providers:(%22Test Provider%22)")
        end
      end
    end

    context "when external search is disabled" do
      before { allow(Mp::Application.config).to receive(:enable_external_search).and_return(false) }

      describe "#organisation_search_link" do
        it "returns the default path" do
          result = deployable_service.organisation_search_link("Test Provider", "/fallback/path")
          expect(result).to eq("/fallback/path")
        end

        it "returns nil if no default path provided" do
          result = deployable_service.organisation_search_link("Test Provider")
          expect(result).to be_nil
        end
      end

      describe "#node_search_link" do
        it "returns the default path" do
          result = deployable_service.node_search_link("Test Node", "/node/path")
          expect(result).to eq("/node/path")
        end
      end

      describe "#provider_search_link" do
        it "returns the default path" do
          result = deployable_service.provider_search_link("Test Provider", "/provider/path")
          expect(result).to eq("/provider/path")
        end
      end
    end
  end

  describe "REQUIRED_METHODS constant" do
    it "defines the methods that implementing classes must provide" do
      expect(OrderableResource::REQUIRED_METHODS).to include(:name)
      expect(OrderableResource::REQUIRED_METHODS).to include(:description)
      expect(OrderableResource::REQUIRED_METHODS).to include(:offers)
      expect(OrderableResource::REQUIRED_METHODS).to include(:resource_organisation)
      expect(OrderableResource::REQUIRED_METHODS).to include(:owned_by?)
    end
  end
end
