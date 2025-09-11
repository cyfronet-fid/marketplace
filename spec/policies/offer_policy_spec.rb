# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfferPolicy, backend: true do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:service_category) { create(:service_category) }

  describe "permissions" do
    describe "#index?" do
      let(:offer) { create(:offer, service: create(:service), offer_category: service_category) }
      subject { OfferPolicy.new(user, offer) }

      it "allows anyone to view index" do
        expect(subject.index?).to be true
      end

      context "when user is anonymous" do
        subject { OfferPolicy.new(nil, offer) }

        it "allows anonymous users to view index" do
          expect(subject.index?).to be true
        end
      end
    end

    describe "#order?" do
      context "with Service offers" do
        let(:service) { create(:service, resource_organisation: provider, status: :published) }
        let(:offer) { create(:offer, service: service, offer_category: service_category, status: :published) }
        subject { OfferPolicy.new(user, offer) }

        it "allows ordering published offers" do
          expect(subject.order?).to be true
        end

        context "when offer is draft" do
          let(:offer) { create(:offer, service: service, offer_category: service_category, status: :draft) }

          it "does not allow ordering" do
            expect(subject.order?).to be false
          end
        end

        context "when offer has limited availability" do
          context "with available count > 0" do
            let(:offer) do
              create(
                :offer,
                service: service,
                offer_category: service_category,
                status: :published,
                limited_availability: true,
                availability_count: 5
              )
            end

            it "allows ordering" do
              expect(subject.order?).to be true
            end
          end

          context "with available count = 0" do
            let(:offer) do
              create(
                :offer,
                service: service,
                offer_category: service_category,
                status: :published,
                limited_availability: true,
                availability_count: 0
              )
            end

            it "does not allow ordering" do
              expect(subject.order?).to be false
            end
          end
        end
      end

      context "with DeployableService offers" do
        let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }
        let(:offer) do
          create(
            :offer,
            deployable_service: deployable_service,
            service: nil,
            offer_category: service_category,
            status: :published
          )
        end
        subject { OfferPolicy.new(user, offer) }

        it "allows ordering published deployable service offers" do
          expect(subject.order?).to be true
        end

        context "when offer is draft" do
          let(:offer) do
            create(
              :offer,
              deployable_service: deployable_service,
              service: nil,
              offer_category: service_category,
              status: :draft
            )
          end

          it "does not allow ordering" do
            expect(subject.order?).to be false
          end
        end

        context "when offer has limited availability" do
          context "with available count > 0" do
            let(:offer) do
              create(
                :offer,
                deployable_service: deployable_service,
                service: nil,
                offer_category: service_category,
                status: :published,
                limited_availability: true,
                availability_count: 3
              )
            end

            it "allows ordering" do
              expect(subject.order?).to be true
            end
          end

          context "with available count = 0" do
            let(:offer) do
              create(
                :offer,
                deployable_service: deployable_service,
                service: nil,
                offer_category: service_category,
                status: :published,
                limited_availability: true,
                availability_count: 0
              )
            end

            it "does not allow ordering" do
              expect(subject.order?).to be false
            end
          end
        end
      end
    end

    describe "#disable_notification?" do
      let(:service) { create(:service, resource_organisation: provider, status: :published) }
      let(:observed_user) { create(:user) }

      context "when user is observing the offer" do
        let(:offer) do
          create(:offer, service: service, offer_category: service_category, status: :published, users: [observed_user])
        end
        subject { OfferPolicy.new(observed_user, offer) }

        context "when offer cannot be ordered (availability = 0)" do
          before { offer.update(limited_availability: true, availability_count: 0) }

          it "allows disabling notification" do
            expect(subject.disable_notification?).to be true
          end
        end

        context "when offer can be ordered" do
          it "does not allow disabling notification" do
            expect(subject.disable_notification?).to be false
          end
        end
      end

      context "when user is not observing the offer" do
        let(:offer) { create(:offer, service: service, offer_category: service_category, status: :published) }
        subject { OfferPolicy.new(user, offer) }

        before { offer.update(limited_availability: true, availability_count: 0) }

        it "does not allow disabling notification" do
          expect(subject.disable_notification?).to be false
        end
      end

      context "when user is anonymous" do
        let(:offer) { create(:offer, service: service, offer_category: service_category, status: :published) }
        subject { OfferPolicy.new(nil, offer) }

        it "does not allow disabling notification" do
          expect(subject.disable_notification?).to be false
        end
      end
    end
  end

  describe OfferPolicy::Scope do
    let!(:provider) { create(:provider) }
    let!(:service) { create(:service, resource_organisation: provider, status: :published) }
    let!(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    # Service offers
    let!(:published_service_offer) do
      create(
        :offer,
        service: service,
        deployable_service: nil,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    let!(:draft_service_offer) do
      create(
        :offer,
        service: service,
        deployable_service: nil,
        status: :draft,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    let!(:bundle_exclusive_service_offer) do
      create(
        :offer,
        service: service,
        deployable_service: nil,
        status: :published,
        bundle_exclusive: true,
        offer_category: service_category
      )
    end

    # DeployableService offers
    let!(:published_ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    let!(:draft_ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        status: :draft,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    let!(:bundle_exclusive_ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        status: :published,
        bundle_exclusive: true,
        offer_category: service_category
      )
    end

    subject { OfferPolicy::Scope.new(user, Offer.all).resolve }

    it "includes published, non-bundle-exclusive Service offers" do
      expect(subject).to include(published_service_offer)
    end

    it "includes published, non-bundle-exclusive DeployableService offers" do
      expect(subject).to include(published_ds_offer)
    end

    it "excludes draft Service offers" do
      expect(subject).not_to include(draft_service_offer)
    end

    it "excludes draft DeployableService offers" do
      expect(subject).not_to include(draft_ds_offer)
    end

    it "excludes bundle-exclusive Service offers" do
      expect(subject).not_to include(bundle_exclusive_service_offer)
    end

    it "excludes bundle-exclusive DeployableService offers" do
      expect(subject).not_to include(bundle_exclusive_ds_offer)
    end

    context "with errored status offers" do
      let!(:errored_service_offer) do
        create(
          :offer,
          service: service,
          deployable_service: nil,
          status: :errored,
          bundle_exclusive: false,
          offer_category: service_category
        )
      end

      let!(:errored_ds_offer) do
        create(
          :offer,
          service: nil,
          deployable_service: deployable_service,
          status: :errored,
          bundle_exclusive: false,
          offer_category: service_category
        )
      end

      it "includes errored Service offers (part of PUBLIC_STATUSES)" do
        expect(subject).to include(errored_service_offer)
      end

      it "includes errored DeployableService offers" do
        expect(subject).to include(errored_ds_offer)
      end
    end

    context "when user is anonymous" do
      subject { OfferPolicy::Scope.new(nil, Offer.all).resolve }

      it "applies same filtering rules" do
        expect(subject).to include(published_service_offer, published_ds_offer)
        expect(subject).not_to include(
          draft_service_offer,
          draft_ds_offer,
          bundle_exclusive_service_offer,
          bundle_exclusive_ds_offer
        )
      end
    end

    context "when scope is empty" do
      subject { OfferPolicy::Scope.new(user, Offer.none).resolve }

      it "returns empty relation" do
        expect(subject).to be_empty
      end
    end

    context "with different statuses" do
      before do
        # Clean up existing offers for cleaner test
        Offer.destroy_all
      end

      let!(:published_offer) do
        create(:offer, service: service, status: :published, bundle_exclusive: false, offer_category: service_category)
      end
      let!(:errored_offer) do
        create(:offer, service: service, status: :errored, bundle_exclusive: false, offer_category: service_category)
      end
      let!(:draft_offer) do
        create(:offer, service: service, status: :draft, bundle_exclusive: false, offer_category: service_category)
      end
      let!(:deleted_offer) do
        create(:offer, service: service, status: :deleted, bundle_exclusive: false, offer_category: service_category)
      end

      it "includes only PUBLIC_STATUSES (published and errored)" do
        resolved_offers = subject
        expect(resolved_offers).to include(published_offer, errored_offer)
        expect(resolved_offers).not_to include(draft_offer, deleted_offer)
      end
    end

    describe "scope performance and simplicity" do
      it "uses simple WHERE clauses without complex JOINs" do
        # The scope should be simple and not include complex JOINs
        sql = subject.to_sql.downcase
        expect(sql).to include("where")
        expect(sql).to include("bundle_exclusive")
        expect(sql).to include("status")

        # Should not include complex JOINs that caused issues before
        expect(sql).not_to include("inner join")
        expect(sql).not_to include("left join")
      end

      it "works with both Service and DeployableService offers" do
        # This tests that the simplified scope doesn't break with mixed offer types
        expect { subject.to_a }.not_to raise_error
        expect(subject.count).to be >= 2 # At least the published offers
      end
    end
  end

  describe "edge cases and compatibility" do
    let(:service) { create(:service, resource_organisation: provider, status: :published) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }

    context "when offer belongs to neither service nor deployable_service" do
      let(:offer) { build(:offer, service: nil, deployable_service: nil, offer_category: service_category) }
      subject { OfferPolicy.new(user, offer) }

      it "handles gracefully for ordering" do
        expect { subject.order? }.not_to raise_error
        # NOTE: order? only checks published? and availability, not parent service validity
        expect(subject.order?).to be true # Will be true if offer is published and available
      end
    end

    context "when offer belongs to both service and deployable_service" do
      let(:offer) do
        build(:offer, service: service, deployable_service: deployable_service, offer_category: service_category)
      end
      subject { OfferPolicy.new(user, offer) }

      it "handles gracefully for ordering" do
        expect { subject.order? }.not_to raise_error
      end
    end

    context "with nil user" do
      let(:offer) { create(:offer, service: service, offer_category: service_category) }
      subject { OfferPolicy.new(nil, offer) }

      it "handles anonymous users for all methods" do
        expect(subject.index?).to be true
        expect { subject.order? }.not_to raise_error
        expect(subject.disable_notification?).to be false
      end
    end
  end

  describe "integration with parent service policies" do
    context "when Service is not visible" do
      let(:service) { create(:service, resource_organisation: provider, status: :draft) }
      let(:offer) { create(:offer, service: service, offer_category: service_category, status: :published) }

      it "OfferPolicy scope still includes the offer (service filtering is handled elsewhere)" do
        scope_result = OfferPolicy::Scope.new(user, Offer.where(id: offer.id)).resolve
        expect(scope_result).to include(offer)
      end
    end

    context "when DeployableService is not visible" do
      let(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :draft) }
      let(:offer) do
        create(
          :offer,
          service: nil,
          deployable_service: deployable_service,
          offer_category: service_category,
          status: :published
        )
      end

      it "OfferPolicy scope still includes the offer (deployable_service filtering is handled elsewhere)" do
        scope_result = OfferPolicy::Scope.new(user, Offer.where(id: offer.id)).resolve
        expect(scope_result).to include(offer)
      end
    end
  end
end
