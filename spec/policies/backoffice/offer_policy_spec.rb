# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::OfferPolicy do
  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:owner) { create(:user) }
  let(:stranger) { create(:user) }
  let(:service) { create(:service, owners: [owner]) }

  subject { described_class }

  permissions :new? do
    let(:offer) { build(:offer, service: service) }

    it "grants access to service portfolio manager" do
      expect(subject).to permit(service_portfolio_manager, offer)
    end

    it "grants access to service owner" do
      expect(subject).to permit(owner, offer)
    end

    it "denies access to other users" do
      expect(subject).to_not permit(stranger, offer)
    end
  end

  permissions :destroy? do
    let(:offer) { create(:offer, service: service) }

    before { create(:project_item, offer: offer) }

    it "denies for all when service is ordered using this offer" do
      expect(subject).to_not permit(service_portfolio_manager, offer)
      expect(subject).to_not permit(owner, offer)
      expect(subject).to_not permit(stranger, offer)
    end
  end

  context "when offer is published" do
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update?, :destroy? do
      it "grants access to service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, offer)
      end

      it "grants access to service owner" do
        expect(subject).to permit(owner, offer)
      end

      it "denies access to other users" do
        expect(subject).to_not permit(stranger, offer)
      end
    end
  end

  context "when offer is a draft" do
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update?, :destroy? do
      it "grants access to service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, offer)
      end

      it "grant access to service owner" do
        expect(subject).to permit(owner, offer)
      end
      it "denies access to other users" do
        expect(subject).to_not permit(stranger, offer)
      end
    end
  end

  context "When offer is published and service is deleted" do
    let(:service) { create(:service, owners: [owner], status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :published) }

    permissions :create?, :edit?, :update?, :destroy?, :draft? do
      it "danies access to service portfolio manager" do
        expect(subject).to_not permit(service_portfolio_manager, offer)
      end

      it "danies access to service owner" do
        expect(subject).to_not permit(owner, offer)
      end
      it "denies access to other users" do
        expect(subject).to_not permit(stranger, offer)
      end
    end
  end

  context "When offer is draft and service is deleted" do
    let(:service) { create(:service, owners: [owner], status: :deleted) }
    let(:offer) { build(:offer, service: service, status: :draft) }

    permissions :create?, :edit?, :update?, :destroy?, :publish? do
      it "danies access to service portfolio manager" do
        expect(subject).to_not permit(service_portfolio_manager, offer)
      end

      it "danies access to service owner" do
        expect(subject).to_not permit(owner, offer)
      end
      it "denies access to other users" do
        expect(subject).to_not permit(stranger, offer)
      end
    end
  end
end
