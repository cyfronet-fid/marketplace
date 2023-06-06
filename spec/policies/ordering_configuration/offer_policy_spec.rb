# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingConfiguration::OfferPolicy, backend: true do
  let(:user) { create(:user) }
  let(:stranger) { create(:user) }
  let(:data_administrator) { create(:data_administrator, email: user.email) }
  let(:provider) { create(:provider, data_administrators: [data_administrator]) }
  let(:service) { create(:service, resource_organisation: provider) }
  let(:offer) { build(:offer, service: service) }

  subject { described_class }

  permissions :new?, :edit?, :create?, :update?, :destroy? do
    it "grants access for data_administrator of service" do
      expect(subject).to permit(user, offer)
    end

    it "denies for other users" do
      expect(subject).to_not permit(stranger, offer)
    end

    it "denies for data administrator of other service" do
      other_service = create(:service, offers: [build(:offer)])

      expect(subject).to_not permit(user, other_service.offers.first)
    end
  end
end
