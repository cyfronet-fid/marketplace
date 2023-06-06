# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::OfferPolicy, type: :policy, backend: true do
  subject { described_class }

  let!(:data_admin_user) { create(:user) }
  let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
  let!(:other_data_admin_user) { create(:user) }
  let(:other_data_admin) { create(:data_administrator, email: other_data_admin_user.email) }
  let!(:service) do
    create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
  end
  let!(:deleted_service) do
    create(
      :service,
      status: :deleted,
      resource_organisation: create(:provider, data_administrators: [data_administrator])
    )
  end
  let!(:offer) { create(:offer, service: service, status: "published") }
  let!(:draft_offer) { create(:offer, service: service, status: "draft") }
  let!(:deleted_offer) { create(:offer, service: service, status: "deleted") }

  let!(:offer_in_deleted_service) { create(:offer, service: deleted_service) }

  permissions ".scope" do
    it "shows only owned and published offers" do
      expect(subject::Scope.new(data_admin_user, service.offers).resolve).to contain_exactly(offer)
      expect(subject::Scope.new(data_admin_user, deleted_service.offers).resolve).to eq([])
      expect(subject::Scope.new(other_data_admin_user, service.offers).resolve).to eq([])
      expect(subject::Scope.new(other_data_admin_user, deleted_service.offers).resolve).to eq([])
    end
  end

  permissions :show?, :update?, :destroy?, :create? do
    it "permits published offer only" do
      expect(subject).to permit(data_admin_user, offer)
      expect(subject).to_not permit(data_admin_user, draft_offer)
      expect(subject).to_not permit(data_admin_user, deleted_offer)
    end

    it "doesn't permit offer in deleted service" do
      expect(subject).to_not permit(data_admin_user, offer_in_deleted_service)
    end

    it "doesn't permit when offer's service is not administrated by user" do
      expect(subject).to_not permit(other_data_admin, offer)
      expect(subject).to_not permit(other_data_admin, draft_offer)
      expect(subject).to_not permit(other_data_admin, deleted_offer)
      expect(subject).to_not permit(other_data_admin, offer_in_deleted_service)
    end
  end
end
