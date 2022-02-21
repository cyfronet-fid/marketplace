# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  describe "validations" do
    subject { build(:offer) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:service) }
    it { should validate_presence_of(:order_type) }
    it { should belong_to(:service) }

    it { should have_many(:project_items).dependent(:restrict_with_error) }
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
      offer = create(:offer, order_type: :open_access, internal: true, primary_oms: oms, oms_params: { a: "qwe" })
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

  context "bundle offer" do
    let!(:source) { create(:offer, bundled_offers: [target]) }
    let(:target) { build(:offer) }

    it "returns linked offer targets" do
      expect(source.bundled_offers).to contain_exactly(target)
    end

    it "remove link when source is removed" do
      expect { source.destroy! }.to change { OfferLink.count }.by(-1)
    end

    it "remove link when target is removed" do
      expect { target.destroy! }.to change { OfferLink.count }.by(-1)
    end

    it "is when there are linked offers" do
      expect(source).to be_bundle
      expect(target).to_not be_bundle
    end
  end

  context "#bundled_offers" do
    context "#bundled_offers_correct" do
      let(:offer) { build(:offer) }

      it "allows empty" do
        expect(offer.valid?).to be_truthy
      end

      it "allows published internal offers" do
        bundled_offer = build(:offer)
        offer.bundled_offers = [bundled_offer]

        expect(offer.valid?).to be_truthy
      end

      Service::PUBLIC_STATUSES.each do |accepted_status|
        it "allows offer from #{accepted_status} service" do
          bundled_offer = build(:offer, service: build(:service, status: accepted_status))
          offer.bundled_offers = [bundled_offer]

          expect(offer.valid?).to be_truthy
        end
      end

      context "non-internal bundle offer" do
        let(:offer) { build(:offer, internal: false) }

        it "allows empty" do
          expect(offer.valid?).to be_truthy
        end

        it "rejects any bundled offer" do
          bundled_offer = build(:offer)
          offer.bundled_offers = [bundled_offer]

          expect_error_messages "only internal offer can have bundled offers"
        end
      end

      context "bundled bundle offer" do
        let(:offer) { build(:offer, bundle_offers: [build(:offer)]) }

        it "allows empty" do
          expect(offer.valid?).to be_truthy
        end

        it "rejects any bundled offer" do
          next_level_bundled_offer = build(:offer)
          offer.bundled_offers = [next_level_bundled_offer]

          expect_error_messages "only non-bundled offer can have bundled offers"
        end
      end

      it "rejects self" do
        offer.bundled_offers = [offer]

        expect_error_messages "cannot bundle self", "cannot bundle bundle offers", "is invalid"
      end

      it "rejects duplicates" do
        bundled_offer = build(:offer)
        offer.bundled_offers = [bundled_offer, bundled_offer]

        expect_error_messages "cannot bundle duplicates"
      end

      it "rejects bundle offers" do
        bundled_offer = build(:offer)
        bundle_offer = build(:offer, bundled_offers: [bundled_offer])
        offer.bundled_offers = [bundle_offer]

        expect_error_messages "cannot bundle bundle offers"
      end

      it "rejects non-internal offers" do
        bundled_offer = build(:offer, internal: false)
        offer.bundled_offers = [bundled_offer]

        expect_error_messages "all bundled offers must be internal"
      end

      Service::STATUSES
        .values
        .reject { |k| Service::PUBLIC_STATUSES.include?(k) }
        .each do |rejected_status|
          it "rejects offer from a #{rejected_status} service" do
            bundled_offer = build(:offer, service: build(:service, status: rejected_status))
            offer.bundled_offers = [bundled_offer]

            expect_error_messages "all bundled offers' services must be public"
          end
        end

      Offer::STATUSES
        .values
        .reject { |k| k == "published" }
        .each do |status|
          it "rejects #{status} offers" do
            bundled_offer = build(:offer, status: status)
            offer.bundled_offers = [bundled_offer]

            expect_error_messages "all bundled offers must be published"
          end
        end

      private

      def expect_error_messages(*msg)
        expect(offer.valid?).to be_falsey
        expect(offer.errors.messages_for(:bundled_offers)).to eq(msg)
      end
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
      expect { Offer.find_by_slug_iid!("no-slug/1") }.to raise_error(
        ActiveRecord::RecordNotFound,
        "Couldn't find Service"
      )
      expect { Offer.find_by_slug_iid!("test-slug/2") }.to raise_error(
        ActiveRecord::RecordNotFound,
        "Couldn't find Offer"
      )
    end
  end
end
