# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::OfferPolicy do
  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:owner) { create(:user) }

  subject { described_class }

  context "when service is a draft" do
    let(:service_draft) { create(:service, status: :draft, owners: [owner]) }

    context "and offer is published" do
      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "grants access to service portfolio manager" do
          expect(subject)
            .to permit(service_portfolio_manager,
                       build(:offer, service: build(:service, status: :draft)))
        end
      end

      permissions :destroy?, :new?, :update?, :edit?, :create? do
        it "denied access to service owner" do
          expect(subject)
            .to_not permit(owner, build(:offer, service: service_draft))
        end
      end
    end

    context "and offer is a draft" do
      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "grants access to service portfolio manager" do
          expect(subject)
            .to permit(service_portfolio_manager,
                       build(:offer, status: :draft,
                             service: build(:service, status: :draft)))
        end
      end

      permissions :destroy?, :new?, :update?, :edit?, :create? do
        it "denied access to service owner" do
          expect(subject)
            .to_not permit(owner,
                           build(:offer, status: :draft, service: service_draft))
        end
      end
    end
  end

  context "when service is published" do
    let(:service_published) { create(:service, status: :published, owners: [owner]) }

    context "and offer is published" do
      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "grants access to service portfolio manager" do
          expect(subject)
            .to permit(service_portfolio_manager,
                       build(:offer, service: build(:service)))
        end
      end

      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "danies access to service owner" do
          expect(subject)
            .to_not permit(owner, build(:offer, service: service_published))
        end
      end
    end

    context "and offer is a draft" do
      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "grants access to service portfolio manager" do
          expect(subject)
            .to permit(service_portfolio_manager,
                       build(:offer, status: :draft, service: build(:service)))
        end
      end

      permissions :new?, :create?, :edit?, :update?, :destroy? do
        it "danies access to service owner" do
          expect(subject)
            .to_not permit(owner,
                           build(:offer, status: :draft, service: service_published))
        end
      end
    end
  end
end
