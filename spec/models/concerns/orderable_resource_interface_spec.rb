# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OrderableResource interface compatibility", type: :model do
  # This spec ensures that both Service and DeployableService implement
  # a compatible interface. This is critical for the ordering wizard,
  # offer associations, and views that need to work with both types.
  #
  # These tests should pass BEFORE and AFTER the OrderableResource
  # concern refactoring.

  let(:provider) { create(:provider) }
  let(:catalogue) { create(:catalogue) }
  let(:service_category) { create(:service_category) }

  shared_examples "orderable resource interface" do |resource_class|
    let(:resource) do
      if resource_class == Service
        # Pass providers: [provider] to override factory sequence
        create(
          :service,
          resource_organisation: provider,
          providers: [provider],
          catalogue: catalogue,
          status: :published
        )
      else
        create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :published)
      end
    end

    describe "#{resource_class} - required attributes" do
      it "responds to name" do
        expect(resource).to respond_to(:name)
        expect(resource.name).to be_a(String)
      end

      it "responds to description" do
        expect(resource).to respond_to(:description)
        expect(resource.description).to be_a(String)
      end

      it "responds to tagline" do
        expect(resource).to respond_to(:tagline)
        expect(resource.tagline).to be_a(String)
      end

      it "responds to slug" do
        expect(resource).to respond_to(:slug)
        expect(resource.slug).to be_a(String)
      end

      it "responds to status" do
        expect(resource).to respond_to(:status)
        expect(resource.status).to be_present
      end

      it "responds to order_type" do
        expect(resource).to respond_to(:order_type)
        expect(resource.order_type).to be_present
      end

      it "responds to abbreviation" do
        expect(resource).to respond_to(:abbreviation)
      end
    end

    describe "#{resource_class} - required associations" do
      it "responds to offers" do
        expect(resource).to respond_to(:offers)
        expect(resource.offers).to respond_to(:to_a)
      end

      it "responds to bundles" do
        expect(resource).to respond_to(:bundles)
      end

      it "responds to resource_organisation" do
        expect(resource).to respond_to(:resource_organisation)
        expect(resource.resource_organisation).to eq(provider)
      end

      it "responds to catalogue" do
        expect(resource).to respond_to(:catalogue)
      end

      it "responds to providers and includes resource_organisation" do
        expect(resource).to respond_to(:providers)
        # NOTE: Service returns CollectionProxy, DeployableService returns Array
        # Both should be enumerable and include the provider
        expect(resource.providers.to_a).to include(provider)
      end

      it "responds to scientific_domains" do
        expect(resource).to respond_to(:scientific_domains)
      end
    end

    describe "#{resource_class} - count methods" do
      it "responds to offers_count" do
        expect(resource).to respond_to(:offers_count)
        expect(resource.offers_count).to be_a(Integer)
      end

      it "responds to bundles_count" do
        expect(resource).to respond_to(:bundles_count)
        expect(resource.bundles_count).to be_a(Integer)
      end
    end

    describe "#{resource_class} - predicate methods" do
      it "responds to offers?" do
        expect(resource).to respond_to(:offers?)
        expect(resource.offers?).to be_in([true, false])
      end

      it "responds to bundles?" do
        expect(resource).to respond_to(:bundles?)
        expect(resource.bundles?).to be_in([true, false])
      end

      it "responds to published?" do
        expect(resource).to respond_to(:published?)
        expect(resource.published?).to eq(true) # We created with status: :published
      end

      it "responds to suspended?" do
        expect(resource).to respond_to(:suspended?)
        expect(resource.suspended?).to eq(false)
      end

      it "responds to draft?" do
        expect(resource).to respond_to(:draft?)
        expect(resource.draft?).to eq(false)
      end

      it "responds to deleted?" do
        expect(resource).to respond_to(:deleted?)
        expect(resource.deleted?).to eq(false)
      end
    end

    describe "#{resource_class} - ownership" do
      let(:other_user) { create(:user) }

      it "responds to owned_by?" do
        expect(resource).to respond_to(:owned_by?)
      end

      it "returns false for non-administrator" do
        expect(resource.owned_by?(other_user)).to eq(false)
      end

      it "handles nil user gracefully" do
        # NOTE: Service and DeployableService handle nil differently
        # DeployableService: returns false
        # Service: raises error (bug to fix in refactoring)
        if resource_class == DeployableService
          expect(resource.owned_by?(nil)).to eq(false)
        else
          # Service currently raises error on nil - this is a known inconsistency
          expect { resource.owned_by?(nil) }.to raise_error(NoMethodError)
        end
      end

      # NOTE: Testing positive ownership case is complex due to different
      # ownership mechanisms (Service: owners/service_user_relationships,
      # DeployableService: data_administrators on resource_organisation).
      # This is tested in the individual model specs.
    end

    describe "#{resource_class} - search links" do
      it "responds to organisation_search_link" do
        expect(resource).to respond_to(:organisation_search_link)
      end

      it "responds to provider_search_link" do
        expect(resource).to respond_to(:provider_search_link)
      end

      it "responds to node_search_link" do
        expect(resource).to respond_to(:node_search_link)
      end
    end

    describe "#{resource_class} - URL helpers" do
      it "responds to to_param" do
        expect(resource).to respond_to(:to_param)
        expect(resource.to_param).to be_present
      end
    end

    describe "#{resource_class} - offers association with scopes" do
      # Create a fresh resource without factory-generated offers
      let(:clean_resource) do
        if resource_class == Service
          create(:service, resource_organisation: provider, catalogue: catalogue, status: :published, offers: [])
        else
          create(:deployable_service, resource_organisation: provider, catalogue: catalogue, status: :published)
        end
      end

      let!(:published_offer) do
        if resource_class == Service
          create(
            :offer,
            service: clean_resource,
            deployable_service: nil,
            offer_category: service_category,
            status: :published,
            bundle_exclusive: false
          )
        else
          create(
            :offer,
            service: nil,
            deployable_service: clean_resource,
            offer_category: service_category,
            status: :published,
            bundle_exclusive: false
          )
        end
      end

      let!(:draft_offer) do
        if resource_class == Service
          create(
            :offer,
            service: clean_resource,
            deployable_service: nil,
            offer_category: service_category,
            status: :draft
          )
        else
          create(
            :offer,
            service: nil,
            deployable_service: clean_resource,
            offer_category: service_category,
            status: :draft
          )
        end
      end

      it "includes offers in the association" do
        clean_resource.reload
        expect(clean_resource.offers).to include(published_offer)
        expect(clean_resource.offers).to include(draft_offer)
      end

      it "offers respond to inclusive scope" do
        expect(clean_resource.offers).to respond_to(:inclusive)
      end

      it "inclusive scope returns only published non-exclusive offers" do
        inclusive = clean_resource.offers.inclusive
        expect(inclusive).to include(published_offer)
        expect(inclusive).not_to include(draft_offer)
      end

      it "offers respond to accessible scope" do
        expect(clean_resource.offers).to respond_to(:accessible)
      end

      it "offers respond to active scope" do
        expect(clean_resource.offers).to respond_to(:active)
      end
    end

    describe "#{resource_class} - wizard compatibility" do
      it "can be used with ProjectItem::Wizard" do
        wizard = nil
        expect { wizard = ProjectItem::Wizard.new(resource) }.not_to raise_error
        expect(wizard).to be_a(ProjectItem::Wizard)
      end

      it "wizard can create steps" do
        wizard = ProjectItem::Wizard.new(resource)
        expect { wizard.step(:choose_offer, {}) }.not_to raise_error
        expect { wizard.step(:information, {}) }.not_to raise_error
        expect { wizard.step(:configuration, {}) }.not_to raise_error
        expect { wizard.step(:summary, {}) }.not_to raise_error
      end
    end

    describe "#{resource_class} - view compatibility methods" do
      # Methods commonly accessed in views
      it "responds to rating" do
        expect(resource).to respond_to(:rating)
      end

      it "responds to popularity_ratio" do
        expect(resource).to respond_to(:popularity_ratio)
      end

      it "responds to service_opinion_count" do
        expect(resource).to respond_to(:service_opinion_count)
      end

      it "responds to horizontal" do
        expect(resource).to respond_to(:horizontal)
      end

      it "responds to public_contacts" do
        expect(resource).to respond_to(:public_contacts)
      end

      it "responds to main_contact" do
        expect(resource).to respond_to(:main_contact)
      end

      it "responds to categories" do
        expect(resource).to respond_to(:categories)
      end

      it "responds to target_users" do
        expect(resource).to respond_to(:target_users)
      end

      it "responds to geographical_availabilities" do
        expect(resource).to respond_to(:geographical_availabilities)
      end
    end
  end

  describe "Service" do
    include_examples "orderable resource interface", Service
  end

  describe "DeployableService" do
    include_examples "orderable resource interface", DeployableService
  end

  describe "cross-type consistency" do
    let(:service) { create(:service, resource_organisation: provider, providers: [provider], status: :published) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    it "both return providers including resource_organisation" do
      # Both should include the provider in their providers list
      # Note: Service.providers returns CollectionProxy, DS returns Array
      expect(service.providers.to_a).to include(provider)
      expect(deployable_service.providers.to_a).to include(provider)
    end

    it "both have consistent status methods" do
      expect(service.published?).to eq(deployable_service.published?)
      expect(service.draft?).to eq(deployable_service.draft?)
    end

    it "both work with policy scope" do
      # Ensure policies work with both types
      expect { Pundit.policy_scope(nil, Service) }.not_to raise_error
      expect { Pundit.policy_scope(nil, DeployableService) }.not_to raise_error
    end
  end
end
