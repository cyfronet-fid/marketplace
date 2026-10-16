# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserIdentity, :backend do
  subject { create(:user_identity) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }

    it { is_expected.to validate_presence_of(:uid) }

    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }
  end

  context "when the user already has a primary identity" do
    subject(:second_identity) { build(:user_identity, user: primary_identity.user, primary: primary) }

    let(:primary_identity) { create(:user_identity, primary: true) }

    context "with another primary identity" do
      let(:primary) { true }

      it "is invalid" do
        expect(second_identity).not_to be_valid
      end

      it "reports the uniqueness error on user_id" do
        second_identity.valid?
        expect(second_identity.errors[:user_id]).to be_present
      end
    end

    context "with a non-primary identity" do
      let(:primary) { false }

      it "is valid" do
        expect(second_identity).to be_valid
      end
    end
  end
end
