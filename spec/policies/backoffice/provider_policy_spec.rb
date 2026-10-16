# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ProviderPolicy, :backend do
  subject { described_class }

  permissions :edit?, :destroy? do
    it "grants access for service portfolio manager" do
      expect(subject).to permit(build(:user, roles: [:coordinator]), build(:provider))
    end

    it "denies for deleted provider" do
      expect(subject).not_to permit(build(:user, roles: [:coordinator]), build(:provider, status: :deleted))
    end

    it "denies for other users" do
      expect(subject).not_to permit(create(:user), build(:provider))
    end

    # Only pl opens the backoffice to admins (pl-marketplace #178).
    it "denies for admin" do
      expect(subject).not_to permit(build(:user, roles: [:admin]), build(:provider))
    end
  end

  permissions :index?, :show? do
    it "grants access for service portfolio manager" do
      expect(subject).to permit(build(:user, roles: [:coordinator]))
    end

    it "denies for other users" do
      user = create(:user)
      expect(subject).not_to permit(user)
    end
  end

  permissions :new?, :create? do
    it "grants access for service portfolio manager" do
      expect(subject).to permit(build(:user, roles: [:coordinator]))
    end

    it "grants access for a first-time provider registration" do
      expect(subject).to permit(create(:user))
    end

    it "denies for unauthenticated users" do
      expect(subject).not_to permit(nil)
    end
  end

  context "when running as pl" do
    before { allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: true, whitelabel?: false) }

    permissions :index?, :new?, :create? do
      it "grants access for any signed-in user" do
        expect(subject).to permit(create(:user))
      end

      it "denies for unauthenticated users" do
        expect(subject).not_to permit(nil)
      end
    end

    permissions :show? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(build(:user, roles: [:coordinator]), build(:provider))
      end

      it "denies for other users" do
        expect(subject).not_to permit(create(:user), build(:provider))
      end
    end

    # pl-marketplace #178: admins manage every provider.
    permissions :show?, :edit?, :update?, :destroy? do
      it "grants access for admin" do
        expect(subject).to permit(build(:user, roles: [:admin]), build(:provider))
      end

      it "denies admin for deleted provider" do
        expect(subject).not_to permit(build(:user, roles: [:admin]), build(:provider, status: :deleted))
      end
    end

    permissions :publish? do
      it "grants access for admin" do
        expect(subject).to permit(build(:user, roles: [:admin]), build(:provider, status: :unpublished))
      end
    end

    it "resolves every provider for admin" do
      providers = create_list(:provider, 2)

      expect(described_class::Scope.new(create(:user, roles: [:admin]), Provider).resolve).to match_array(providers)
    end

    it "does not lock registry-imported providers to internal fields" do
      policy = described_class.new(build(:user, roles: [:coordinator]), build(:provider, upstream_id: 1))

      expect(policy.permitted_attributes).to include(:name)
    end

    it "permits the PL profile and V5 fields" do
      policy = described_class.new(build(:user, roles: [:coordinator]), build(:provider))

      expect(policy.permitted_attributes).to include(:street_name_and_number, :city, [network_ids: []])
    end
  end

  context "when running as whitelabel" do
    before { allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true) }

    permissions :index?, :show?, :new?, :create? do
      it "grants access for any signed-in user" do
        expect(subject).to permit(create(:user), build(:provider))
      end

      it "denies for unauthenticated users" do
        expect(subject).not_to permit(nil, build(:provider))
      end
    end

    it "permits node_ids as a scalar" do
      policy = described_class.new(build(:user, roles: [:coordinator]), build(:provider))

      expect(policy.permitted_attributes).to include(:node_ids)
    end
  end
end
