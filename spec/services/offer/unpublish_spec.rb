# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Unpublish, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if no bundle offers" do
      drafted_offer = create(:offer)

      expect { described_class.call(drafted_offer) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    context "Bundle mutations" do
      let!(:provider) { build(:provider) }
      let!(:bundled_offer) { create(:offer, service: build(:service, resource_organisation: provider)) }
      let!(:bundle_offer) { create(:offer, service: build(:service, resource_organisation: provider)) }
      let!(:bundle) do
        create(:bundle, service: bundle_offer.service, main_offer: bundle_offer, offers: [bundled_offer])
      end

      it "sends notification if bundled offer drafted" do
        expect { described_class.call(bundled_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

        bundled_offer.reload
        bundle.reload

        expect(bundle.valid?).to be_truthy
        expect(bundle).to be_draft
      end

      it "change to draft for main offer" do
        expect { described_class.call(bundle_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

        bundle_offer.reload
        bundle.reload

        expect(bundle_offer.valid?).to be_truthy
        expect(bundle_offer).to be_unpublished
        expect(bundle).to be_unpublished
      end
    end
  end
end
