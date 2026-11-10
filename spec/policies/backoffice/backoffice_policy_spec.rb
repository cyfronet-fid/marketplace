# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::BackofficePolicy, :backend do
  subject { described_class }

  let(:record) { %i[backoffice backoffice] }

  permissions :show? do
    it "grants access for coordinator" do
      expect(subject).to permit(build(:user, roles: [:coordinator]), record)
    end

    # Only pl opens the backoffice to executives and admins (pl-marketplace #178).
    it "denies for executive" do
      expect(subject).not_to permit(build(:user, roles: [:executive]), record)
    end

    it "denies for admin" do
      expect(subject).not_to permit(build(:user, roles: [:admin]), record)
    end

    context "when running as pl" do
      before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

      it "grants access for executive" do
        expect(subject).to permit(build(:user, roles: [:executive]), record)
      end

      it "grants access for admin" do
        expect(subject).to permit(build(:user, roles: [:admin]), record)
      end
    end

    it "grants access for provider data administrator" do
      user = create(:user)
      create(:provider, data_administrators: [build(:data_administrator, email: user.email)])

      expect(subject).to permit(user.reload, record)
    end

    it "grants access for catalogue data administrator" do
      user = create(:user)
      create(:catalogue, data_administrators: [build(:data_administrator, email: user.email)])

      expect(subject).to permit(user.reload, record)
    end

    it "denies for normal user" do
      expect(subject).not_to permit(build(:user), record)
    end

    it "denies for anonymous user" do
      expect(subject).not_to permit(nil, record)
    end
  end
end
