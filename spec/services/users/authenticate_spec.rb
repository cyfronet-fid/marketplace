# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Authenticate, :backend do
  subject(:result) { described_class.call(auth) }

  let(:auth) do
    {
      "provider" => "checkin",
      "uid" => uid,
      "info" => {
        "email" => email,
        "email_verified" => true,
        "first_name" => "John",
        "last_name" => "Doe"
      }
    }
  end

  let(:uid) { "uid-123" }
  let(:email) { "john.doe@email.pl" }

  before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

  context "when an identity already exists for the provider and uid" do
    let!(:identity) { create(:user_identity, provider: "checkin", uid: uid, primary: false) }

    before { result }

    it "returns the identity's user" do
      expect(result).to eq(identity.user)
    end

    it "does not create a new user" do
      expect(User.count).to eq(1)
    end
  end

  context "when no identity matches but a user exists with the same email" do
    let!(:existing_user) { create(:user, email: email) }

    before { result }

    it "returns the existing user" do
      expect(result).to eq(existing_user)
    end

    it "adds a non-primary identity for the provider and uid" do
      expect(existing_user.identities.find_by(provider: "checkin", uid: uid)).to have_attributes(primary: false)
    end
  end

  context "when the email matches one user but the provider/uid identity already belongs to another" do
    let!(:email_matched_user) { create(:user, email: email) }
    let!(:identity) { create(:user_identity, provider: "checkin", uid: uid, primary: false) }

    before { result }

    it "returns the identity's owner instead of the email-matched user" do
      expect(result).to eq(identity.user)
    end

    it "does not create a new user" do
      expect(User.count).to eq(2)
    end

    it "does not attach the identity to the email-matched user" do
      expect(email_matched_user.identities.find_by(provider: "checkin", uid: uid)).to be_nil
    end
  end

  context "when neither an identity nor an email match exists" do
    before { result }

    it "creates a new user" do
      expect(User.count).to eq(1)
    end

    it "creates a primary identity for the new user" do
      expect(result.identities.find_by(provider: "checkin", uid: uid)).to have_attributes(primary: true)
    end
  end
end
