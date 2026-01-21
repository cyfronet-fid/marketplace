# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer, backend: true do
  describe "validations" do
    subject { build(:offer) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:order_type) }
    it { should belong_to(:orderable) }

    it { should have_many(:project_items).dependent(:restrict_with_error) }

    describe "orderable presence validation" do
      it "is valid with service as orderable" do
        offer = build(:offer, service: create(:service))
        expect(offer).to be_valid
      end

      it "is valid with deployable_service as orderable" do
        offer = build(:offer, deployable_service: create(:deployable_service))
        expect(offer).to be_valid
      end

      it "is invalid without orderable" do
        offer = Offer.new(name: "test", description: "test", order_type: :order_required, orderable: nil)
        expect(offer).not_to be_valid
        expect(offer.errors[:base]).to include("Must belong to either service or deployable service")
      end
    end
  end

  context "OMS dependencies" do
    it "validates properly against primary oms" do
      oms = create(:oms, custom_params: { a: { mandatory: false }, b: { mandatory: true, default: "XD" } })

      expect(build(:offer, oms_params: { a: 1, b: 2 }, primary_oms: oms)).to be_valid
      expect(build(:offer, oms_params: { b: 1 }, primary_oms: oms)).to be_valid

      expect(build(:offer, oms_params: { a: 1 }, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: { a: 1, b: 1, c: 1 }, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: nil, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: { b: 1, c: 1 }, primary_oms: build(:oms, custom_params: nil))).to_not be_valid

      expect(build(:offer, oms_params: { c: 1 }, primary_oms: nil)).to_not be_valid
      create(:default_oms, custom_params: { c: { mandatory: true, default: "c" } })
      expect(build(:offer, oms_params: { c: 1 }, primary_oms: nil)).to be_valid

      laid_back_oms = create(:oms, custom_params: { d: { mandatory: false } })
      expect(build(:offer, oms_params: nil, primary_oms: laid_back_oms)).to be_valid
    end

    it "returns proper current_oms" do
      oms = create(:oms)
      expect(build(:offer, primary_oms: oms).current_oms).to eql(oms)
      expect(build(:offer, primary_oms: nil).current_oms).to be_nil

      default_oms = create(:default_oms)
      expect(build(:offer, primary_oms: oms).current_oms).to eql(oms)
      expect(build(:offer, primary_oms: nil).current_oms).to eql(default_oms)
    end
  end

  context "before_validate hooks" do
    it "should set primary_oms and oms_params to nil when internal == false on create" do
      oms = create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "asd" } })
      offer = create(:offer, order_type: :order_required, internal: false, primary_oms: oms, oms_params: { a: "qwe" })
      expect(offer.primary_oms).to be_nil
      expect(offer.oms_params).to be_nil
    end

    it "should set primary_oms and oms_params to nil when internal == true on update" do
      oms = create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "asd" } })
      offer = create(:offer, order_type: :order_required, internal: true, primary_oms: oms, oms_params: { a: "qwe" })
      expect(offer.primary_oms).to eq(oms)
      expect(offer.oms_params).to eq({ a: "qwe" }.deep_stringify_keys)

      offer.update(internal: false)
      offer.reload

      expect(offer.primary_oms).to be_nil
      expect(offer.oms_params).to be_nil
    end

    it "should set internal to false and primary_oms, oms_params to nil when order_type != order_required on create" do
      oms = create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "asd" } })
      service = create(:service, order_type: :open_access)
      offer =
        create(
          :offer,
          service: service,
          order_type: :open_access,
          internal: true,
          primary_oms: oms,
          oms_params: {
            a: "qwe"
          }
        )
      expect(offer.internal).to be_falsey
      expect(offer.primary_oms).to be_nil
      expect(offer.oms_params).to be_nil
    end

    it "should set internal to false and primary_oms, oms_params to nil when order_type != order_required on update" do
      oms = create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "asd" } })
      service = create(:service, offers: [create(:offer)])
      offer =
        create(
          :offer,
          service: service,
          order_type: :order_required,
          internal: true,
          primary_oms: oms,
          oms_params: {
            a: "qwe"
          }
        )
      expect(offer.internal).to be_truthy
      expect(offer.primary_oms).to eq(oms)
      expect(offer.oms_params).to eq({ a: "qwe" }.deep_stringify_keys)

      offer.update(order_type: :open_access)
      offer.reload

      expect(offer.internal).to be_falsey
      expect(offer.primary_oms).to be_nil
      expect(offer.oms_params).to be_nil
    end
  end

  context "#parameters" do
    it "should defaults to []" do
      expect(create(:offer).reload.parameters).to eq([])
    end
  end

  context "primary_oms_exists?" do
    it "should validate if primary_oms_exists" do
      oms = create(:oms, type: :global)
      expect(build(:offer, primary_oms_id: oms.id)).to be_valid
      expect(build(:offer, primary_oms_id: oms.id + 1)).to_not be_valid
    end
  end

  context "proper_oms?" do
    it "should validate if set oms is available for current offer" do
      provider = create(:provider)
      service = create(:service, resource_organisation: provider)

      default_oms = create(:default_oms)
      provider_group_oms = create(:oms, type: :provider_group, providers: [provider])
      resource_dedicated_oms = create(:oms, type: :resource_dedicated, service: service)
      global_oms = create(:oms, type: :global)

      some_other_resource_oms = create(:resource_dedicated_oms)
      some_other_provider_oms = create(:provider_group_oms)

      expect(build(:offer, service: service, primary_oms: default_oms)).to be_valid
      expect(build(:offer, service: service, primary_oms: provider_group_oms)).to be_valid
      expect(build(:offer, service: service, primary_oms: resource_dedicated_oms)).to be_valid
      expect(build(:offer, service: service, primary_oms: global_oms)).to be_valid
      expect(build(:offer, service: service, primary_oms: nil)).to be_valid

      expect(build(:offer, service: service, primary_oms: some_other_resource_oms)).to_not be_valid
      expect(build(:offer, service: service, primary_oms: some_other_provider_oms)).to_not be_valid
    end
  end

  context "#find_by_slug_iid!" do
    context "errors on non-string" do
      [123, nil, []].each do |val|
        it "#{val.nil? ? "nil" : val}" do
          expect { Offer.find_by_slug_iid!(val) }.to raise_error(ArgumentError, "must be a string")
        end
      end
    end

    context "errors on wrong number of components" do
      ["", "123", "1/2/3", "//"].each do |val|
        it val do
          expect { Offer.find_by_slug_iid!(val) }.to raise_error(
            ArgumentError,
            "must have the two components separated with a forward slash '/'"
          )
        end
      end
    end

    it "returns the offer" do
      offer = create(:offer, iid: 3, service: build(:service, slug: "test-slug"))
      expect(Offer.find_by_slug_iid!("test-slug/3")).to eq(offer)
    end

    it "defaults to 0 for non-numeric iids" do
      offer = create(:offer, iid: 0, service: build(:service, slug: "test-slug"))
      expect(Offer.find_by_slug_iid!("test-slug/abc")).to eq(offer)
    end

    it "errors on record not found" do
      create(:offer, iid: 3, service: build(:service, slug: "test-slug"))
      expect { Offer.find_by_slug_iid!("no-slug/1") }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Offer.find_by_slug_iid!("test-slug/2") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "scopes with mixed Service and DeployableService offers" do
    let!(:provider) { create(:provider) }
    let!(:service) { create(:service, resource_organisation: provider, status: :published) }
    let!(:deployable_service) { create(:deployable_service, resource_organisation: provider, status: :published) }
    let!(:service_category) { create(:service_category) }

    let!(:service_offer) do
      create(:offer, service: service, status: :published, bundle_exclusive: false, offer_category: service_category)
    end

    let!(:deployable_service_offer) do
      create(
        :offer,
        deployable_service: deployable_service,
        status: :published,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    let!(:draft_service_offer) do
      create(:offer, service: service, status: :draft, bundle_exclusive: false, offer_category: service_category)
    end

    let!(:draft_deployable_offer) do
      create(
        :offer,
        deployable_service: deployable_service,
        status: :draft,
        bundle_exclusive: false,
        offer_category: service_category
      )
    end

    describe ".inclusive" do
      it "includes published Service offers with published services" do
        expect(Offer.inclusive).to include(service_offer)
      end

      it "includes published DeployableService offers with published deployable services" do
        expect(Offer.inclusive).to include(deployable_service_offer)
      end

      it "excludes draft offers" do
        expect(Offer.inclusive).not_to include(draft_service_offer)
        expect(Offer.inclusive).not_to include(draft_deployable_offer)
      end

      it "excludes offers from unpublished services" do
        service.update(status: :draft)
        expect(Offer.inclusive).not_to include(service_offer)
      end

      it "excludes offers from unpublished deployable services" do
        deployable_service.update(status: :draft)
        expect(Offer.inclusive).not_to include(deployable_service_offer)
      end

      it "excludes bundle exclusive offers" do
        bundle_exclusive_offer =
          create(:offer, service: service, status: :published, bundle_exclusive: true, offer_category: service_category)
        expect(Offer.inclusive).not_to include(bundle_exclusive_offer)
      end

      it "handles service-only offers when deployable service is missing" do
        expect(Offer.inclusive.where(orderable: service)).to include(service_offer)
      end

      it "handles deployable service offers when service is missing" do
        expect(Offer.inclusive.where(orderable: deployable_service)).to include(deployable_service_offer)
      end
    end

    describe ".accessible" do
      it "includes published Service offers with published services" do
        expect(Offer.accessible).to include(service_offer)
      end

      it "includes published DeployableService offers with published deployable services" do
        expect(Offer.accessible).to include(deployable_service_offer)
      end

      it "excludes draft offers" do
        expect(Offer.accessible).not_to include(draft_service_offer)
        expect(Offer.accessible).not_to include(draft_deployable_offer)
      end

      it "excludes offers from unpublished services" do
        service.update(status: :draft)
        expect(Offer.accessible).not_to include(service_offer)
      end

      it "excludes offers from unpublished deployable services" do
        deployable_service.update(status: :draft)
        expect(Offer.accessible).not_to include(deployable_service_offer)
      end

      it "includes bundle exclusive offers (accessible allows them)" do
        bundle_exclusive_offer =
          create(:offer, service: service, status: :published, bundle_exclusive: true, offer_category: service_category)
        expect(Offer.accessible).to include(bundle_exclusive_offer)
      end
    end

    describe ".active" do
      let!(:limited_offer) do
        create(
          :offer,
          service: service,
          status: :published,
          bundle_exclusive: false,
          limited_availability: true,
          availability_count: 5,
          offer_category: service_category
        )
      end

      let!(:unlimited_offer) do
        create(
          :offer,
          deployable_service: deployable_service,
          status: :published,
          bundle_exclusive: false,
          limited_availability: false,
          offer_category: service_category
        )
      end

      let!(:exhausted_offer) do
        create(
          :offer,
          service: service,
          status: :published,
          bundle_exclusive: false,
          limited_availability: true,
          availability_count: 0,
          offer_category: service_category
        )
      end

      it "includes unlimited offers" do
        expect(Offer.active).to include(unlimited_offer)
        expect(Offer.active).to include(service_offer) # default limited_availability: false
        expect(Offer.active).to include(deployable_service_offer)
      end

      it "includes limited offers with availability" do
        expect(Offer.active).to include(limited_offer)
      end

      it "excludes exhausted offers" do
        expect(Offer.active).not_to include(exhausted_offer)
      end

      it "excludes bundle exclusive offers" do
        bundle_offer =
          create(
            :offer,
            service: service,
            status: :published,
            bundle_exclusive: true,
            limited_availability: false,
            offer_category: service_category
          )
        expect(Offer.active).not_to include(bundle_offer)
      end

      it "excludes draft offers" do
        expect(Offer.active).not_to include(draft_service_offer)
        expect(Offer.active).not_to include(draft_deployable_offer)
      end
    end
  end

  describe "parent_service method" do
    let(:service) { create(:service) }
    let(:deployable_service) { create(:deployable_service) }
    let(:service_category) { create(:service_category) }

    it "returns service when offer belongs to service" do
      offer = create(:offer, service: service, offer_category: service_category)
      expect(offer.parent_service).to eq(service)
    end

    it "returns deployable_service when offer belongs to deployable_service" do
      offer = create(:offer, deployable_service: deployable_service, offer_category: service_category)
      expect(offer.parent_service).to eq(deployable_service)
    end

    it "returns nil when offer has no orderable" do
      offer = Offer.new(name: "test", description: "test", order_type: :order_required)
      expect(offer.parent_service).to be_nil
    end
  end
end
