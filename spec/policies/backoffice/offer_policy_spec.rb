# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::OfferPolicy do
  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:service_owner) do
    create(:user).tap do |user|
      service_draft = create(:service, status: :draft)
      service_published = create(:service, status: :published)
      ServiceUserRelationship.create!(user: user, service: service_draft)
      ServiceUserRelationship.create!(user: user, service: service_published)
    end
  end

  subject { described_class }

  context "Service draft" do
    permissions :new?, :create? do
      it "grants access service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:offer, service: build(:service, status: :draft)))
      end
    end

    permissions :edit?, :update? do
      it "grants access service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:offer, service: build(:service, status: :draft)))
      end
    end

    permissions :destroy? do
      it "grants access service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:offer, service: build(:service, status: :draft)))
      end
    end

    permissions :destroy?, :new?, :update?, :edit?, :create? do
      it "denied access  service owner" do
        expect(subject).to_not permit(service_owner, build(:offer, service: service_owner.owned_services.draft.first))
      end
    end
  end

  context "service published" do

    permissions :new?, :create? do
      it "grants access service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:offer, service: build(:service)))
      end
    end

    permissions  :edit?, :update?, :destroy? do
      it "danied access service portfolio manager" do
        expect(subject).to_not permit(service_portfolio_manager, build(:offer, service:  build(:service)))
      end
    end

    permissions :new?, :create?, :edit?, :update?, :destroy? do
      it "danies access service owner" do
        expect(subject).to_not permit(service_owner, build(:offer, service: service_owner.owned_services.published.first))
      end
    end
  end
end
