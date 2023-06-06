# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Destroy, backend: true do
  context "#bundled_offers" do
    it "doesn't send notification if no bundle offers" do
      destroyed_offer = create(:offer)

      expect { Offer::Destroy.call(destroyed_offer) }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "sends notification if offer unbundled" do
      provider = build(:provider)
      bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
      bundle_offer =
        create(
          :offer,
          service: build(:service, resource_organisation: provider),
          bundled_connected_offers: [bundled_offer]
        )

      expect { Offer::Destroy.call(bundled_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      bundle_offer.reload
      expect(bundle_offer.bundled_connected_offers).to be_blank
    end

    context "with project items" do
      it "doesn't send notification if no bundle offers" do
        destroyed_offer = create(:offer)
        create(:project_item, offer: destroyed_offer)

        expect { Offer::Destroy.call(destroyed_offer) }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "sends notification if offer unbundled" do
        provider = build(:provider)
        destroyed_bundled_offer = build(:offer, service: build(:service, resource_organisation: provider))
        bundle_offer =
          create(
            :offer,
            service: build(:service, resource_organisation: provider),
            bundled_connected_offers: [destroyed_bundled_offer]
          )
        create(:project_item, offer: destroyed_bundled_offer)

        expect { Offer::Destroy.call(destroyed_bundled_offer) }.to change { ActionMailer::Base.deliveries.count }.by(1)

        bundle_offer.reload
        expect(bundle_offer.bundled_connected_offers).to be_blank
      end
    end
  end
end
