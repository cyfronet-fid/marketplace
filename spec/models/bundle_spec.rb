# frozen_string_literal: true

require "rails_helper"

PRETTY_OFFER_TYPE = {
  offer: "internal orderable",
  open_access_offer: "open access",
  fully_open_access_offer: "fully open access",
  other_offer: "other",
  external_offer: "external orderable"
}.freeze

RSpec.describe Bundle, type: :model, backend: true do
  describe "validations" do
    subject { build(:bundle) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:order_type) }
    it { should belong_to(:service).required(true) }
    it { should belong_to(:main_offer).required(true) }
    it { should belong_to(:resource_organisation).required(true) }
  end

  context "bundle" do
    let!(:target) { create(:offer) }
    let!(:source) { create(:offer) }
    let!(:bundle) { create(:bundle, main_offer: source, offers: [target]) }

    it "returns linked offer targets" do
      expect(source.main_bundles.first.offers).to contain_exactly(target)
    end

    it "unables to delete main_offer" do
      expect { source.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end

    it "remove link when target is removed" do
      expect { target.destroy! }.to change { BundleOffer.count }.by(-1)
    end

    it "is when there are linked offers" do
      expect(source).to be_bundle
      expect(target).to_not be_bundle
    end
  end

  context "#bundled_offers" do
    %i[offer open_access_offer fully_open_access_offer other_offer external_offer].each do |type|
      context "#correct main offer with #{PRETTY_OFFER_TYPE[type]} type" do
        let(:offer) { build(type) }
        let(:bundle) { build(:bundle, main_offer: offer) }

        it "allows empty" do
          expect(offer.valid?).to be_truthy
        end

        it "allows published offers" do
          bundled_offer = build(:offer)
          bundle = create(:bundle, main_offer: offer, offers: [bundled_offer])

          expect(bundle.valid?).to be_truthy
        end

        Service::PUBLIC_STATUSES.each do |accepted_status|
          it "allows offer from #{accepted_status} service" do
            bundled_offer = build(:offer, service: build(:service, status: accepted_status))
            bundle.offers = [bundled_offer]

            expect(bundle.valid?).to be_truthy
          end
        end

        Offer::STATUSES
          .values
          .reject { |k| k == "published" }
          .each do |status|
            it "rejects publishing bundle with a #{status} offer" do
              bundle.status = :draft
              bundle.main_offer.status = status

              publisher = Bundle::Publish

              expect(publisher.call(bundle)).to eq(false)
              expect_error_messages "must be published", field: :main_offer
            end
          end

        context "#{PRETTY_OFFER_TYPE[type]} type offer connected to bundle" do
          let(:offer) { create(type, bundles: [build(:bundle)]) }
          let(:bundle) { offer.bundles.first }

          it "allows empty" do
            expect(offer.valid?).to be_truthy
          end

          it "rejects self" do
            bundle.offers = [bundle.main_offer]

            expect_error_messages "cannot bundle main offer"
          end

          it "removes duplicates" do
            bundled_offer = build(:offer)
            bundle.offers = [bundled_offer, bundled_offer]

            expect(bundle.valid?).to be_truthy
            bundle.save
            expect(bundle.offers.size).to eq(1)
          end

          it "allows bundled offers" do
            bundled_offer = build(:offer)
            bundle_offer = build(:offer)
            build(:bundle, main_offer: bundle_offer, offers: [bundled_offer])
            bundle = build(:bundle, offers: [bundle_offer])

            expect(bundle.valid?).to be_truthy
            expect(bundle.offers).to contain_exactly(bundle_offer)
          end

          Service::STATUSES
            .values
            .reject { |k| Service::PUBLIC_STATUSES.include?(k) }
            .each do |rejected_status|
              it "rejects #{PRETTY_OFFER_TYPE[type]} offer from a #{rejected_status} service" do
                bundled_offer = build(type)
                bundled_offer.service.status = rejected_status
                bundle.offers = [bundled_offer]

                expect_error_messages "must have offers with public services selected"
              end

              it "rejects publishing bundle with a #{rejected_status} service" do
                bundle.status = :draft
                bundle.offers = [build(:offer, status: rejected_status)]

                publisher = Bundle::Publish

                expect(publisher.call(bundle)).to eq(false)
                expect_error_messages "must have only published offers selected"
              end

              it "rejects publishing bundle with a #{rejected_status} service" +
                   " and #{PRETTY_OFFER_TYPE[type]} offer type" do
                bundle.status = :draft
                bundle.offers = [build(type, status: rejected_status)]

                publisher = Bundle::Publish

                expect(publisher.call(bundle)).to eq(false)
                expect_error_messages "must have only published offers selected"
              end
            end

          Offer::STATUSES
            .values
            .reject { |k| k == "published" }
            .each do |status|
              it "rejects #{status} offers" do
                bundled_offer = build(:offer, status: status)
                bundle.offers = [bundled_offer]

                expect_error_messages "must have only published offers selected"
              end
            end
        end
      end
    end
  end

  private

  def expect_error_messages(*msg, field: :offers)
    expect(bundle.valid?).to be_falsey
    expect(bundle.errors.messages_for(field)).to eq(msg)
  end
end
