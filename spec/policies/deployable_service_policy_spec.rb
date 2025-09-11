# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableServicePolicy, backend: true do
  subject { DeployableServicePolicy.new(user, deployable_service) }

  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }

  describe "permissions" do
    describe "#index?" do
      it "allows anyone to view index" do
        expect(subject.index?).to be true
      end

      context "when user is nil (anonymous)" do
        subject { DeployableServicePolicy.new(nil, deployable_service) }

        it "allows anonymous users to view index" do
          expect(subject.index?).to be true
        end
      end
    end

    describe "#show?" do
      context "when deployable service is published" do
        let(:deployable_service) { create(:deployable_service, status: :published, resource_organisation: provider) }

        it "allows viewing" do
          expect(subject.show?).to be true
        end
      end

      context "when deployable service is errored" do
        let(:deployable_service) { create(:deployable_service, status: :errored, resource_organisation: provider) }

        it "allows viewing" do
          expect(subject.show?).to be true
        end
      end

      context "when deployable service is draft" do
        let(:deployable_service) { create(:deployable_service, status: :draft, resource_organisation: provider) }

        it "raises RecordNotFound" do
          expect { subject.show? }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when deployable service is deleted" do
        let(:deployable_service) { create(:deployable_service, status: :deleted, resource_organisation: provider) }

        it "raises RecordNotFound" do
          expect { subject.show? }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "#offers_show?" do
      let(:service_category) { create(:service_category) }

      context "when deployable service has published non-bundle-exclusive offers" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "allows viewing offers" do
          expect(subject.offers_show?).to be true
        end
      end

      context "when deployable service has only bundle-exclusive offers" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: true,
            offer_category: service_category
          )
        end

        it "does not allow viewing offers" do
          expect(subject.offers_show?).to be false
        end
      end

      context "when deployable service has only draft offers" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :draft,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "does not allow viewing offers" do
          expect(subject.offers_show?).to be false
        end
      end

      context "when deployable service has no offers" do
        it "does not allow viewing offers" do
          expect(subject.offers_show?).to be false
        end
      end

      context "when deployable service has mixed offers" do
        before do
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
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: true,
            offer_category: service_category
          )
        end

        it "allows viewing offers (at least one non-bundle-exclusive published offer)" do
          expect(subject.offers_show?).to be true
        end
      end
    end

    describe "#bundles_show?" do
      it "always returns false for deployable services" do
        expect(subject.bundles_show?).to be false
      end

      context "even when deployable service has offers" do
        let(:service_category) { create(:service_category) }

        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "returns false" do
          expect(subject.bundles_show?).to be false
        end
      end
    end
  end

  describe DeployableServicePolicy::Scope do
    let!(:published_ds) { create(:deployable_service, status: :published, resource_organisation: provider) }
    let!(:errored_ds) { create(:deployable_service, status: :errored, resource_organisation: provider) }
    let!(:draft_ds) { create(:deployable_service, status: :draft, resource_organisation: provider) }
    let!(:deleted_ds) { create(:deployable_service, status: :deleted, resource_organisation: provider) }

    subject { DeployableServicePolicy::Scope.new(user, DeployableService.all).resolve }

    it "includes published deployable services" do
      expect(subject).to include(published_ds)
    end

    it "includes errored deployable services" do
      expect(subject).to include(errored_ds)
    end

    it "excludes draft deployable services" do
      expect(subject).not_to include(draft_ds)
    end

    it "excludes deleted deployable services" do
      expect(subject).not_to include(deleted_ds)
    end

    context "when user is anonymous" do
      subject { DeployableServicePolicy::Scope.new(nil, DeployableService.all).resolve }

      it "applies same filtering rules" do
        expect(subject).to include(published_ds, errored_ds)
        expect(subject).not_to include(draft_ds, deleted_ds)
      end
    end

    context "when scope is empty" do
      subject { DeployableServicePolicy::Scope.new(user, DeployableService.none).resolve }

      it "returns empty relation" do
        expect(subject).to be_empty
      end
    end
  end

  describe "private methods" do
    let(:service_category) { create(:service_category) }

    describe "#any_published_offers?" do
      context "when deployable service has published non-bundle offers" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "returns true" do
          expect(subject.send(:any_published_offers?)).to be true
        end
      end

      context "when deployable service has no offers" do
        it "returns false" do
          expect(subject.send(:any_published_offers?)).to be false
        end
      end

      context "when all offers are bundle exclusive" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: true,
            offer_category: service_category
          )
        end

        it "returns false" do
          expect(subject.send(:any_published_offers?)).to be false
        end
      end

      context "when all offers are draft" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :draft,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "returns false" do
          expect(subject.send(:any_published_offers?)).to be false
        end
      end
    end

    describe "#any_published_bundled_offers?" do
      it "always returns false" do
        expect(subject.send(:any_published_bundled_offers?)).to be false
      end

      context "even with offers present" do
        before do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            status: :published,
            bundle_exclusive: false,
            offer_category: service_category
          )
        end

        it "returns false" do
          expect(subject.send(:any_published_bundled_offers?)).to be false
        end
      end
    end
  end

  describe "edge cases" do
    context "when deployable service has no resource organisation" do
      let(:deployable_service) { build(:deployable_service, resource_organisation: nil) }

      it "handles missing provider gracefully" do
        expect { subject.show? }.not_to raise_error
      end
    end

    context "when deployable service offers association returns nil" do
      before { allow(deployable_service).to receive(:offers?).and_return(false) }

      it "handles nil offers gracefully" do
        expect(subject.offers_show?).to be false
      end
    end

    context "when deployable service offers collection is empty" do
      before { allow(deployable_service).to receive(:offers).and_return([]) }

      it "handles empty offers collection" do
        expect(subject.offers_show?).to be false
      end
    end
  end

  describe "compatibility with Service duck-typing" do
    # Test that DeployableServicePolicy works with Service-like interface
    let(:service_category) { create(:service_category) }

    before do
      create(
        :offer,
        deployable_service: deployable_service,
        service: nil,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    it "supports offers? method through duck-typing" do
      expect(deployable_service).to respond_to(:offers?)
      expect(subject.offers_show?).to be true
    end

    it "supports offers collection access" do
      expect(deployable_service.offers).to be_present
      expect(subject.offers_show?).to be true
    end
  end
end
