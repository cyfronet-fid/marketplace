# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Destroy, :backend do
  describe "#bundled_offers" do
    it "doesn't send notification if no bundle offers" do
      destroyed_offer = create(:offer)

      expect { described_class.call(destroyed_offer) }.not_to have_enqueued_mail
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer = create(:offer, service: build(:service, resource_organisation: provider))
      bundle = create(:bundle, service: bundle_offer.service, offers: [bundled_offer])

      expect { described_class.call(bundled_offer) }.to have_enqueued_mail(OfferMailer, :offer_unbundled)

      bundle.reload
      expect(bundle).to be_draft
    end

    context "with project items" do
      it "doesn't send notification if no bundle offers" do
        destroyed_offer = create(:offer)
        create(:project_item, offer: destroyed_offer)

        expect { described_class.call(destroyed_offer) }.not_to have_enqueued_mail
      end

      it "sends notification if offer unbundled" do
        provider = build(:provider)
        destroyed_bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
        bundle_offer = create(:offer, service: build(:service, resource_organisation: provider))
        bundle = create(:bundle, main_offer: bundle_offer, offers: [destroyed_bundled_offer])
        create(:project_item, offer: destroyed_bundled_offer)

        expect { described_class.call(destroyed_bundled_offer) }.to have_enqueued_mail(OfferMailer, :offer_unbundled)

        bundle.reload
        expect(bundle).to be_draft
      end
    end
  end
end
