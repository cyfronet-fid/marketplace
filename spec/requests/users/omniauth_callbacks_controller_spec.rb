# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :request do
  let(:uid) { "checkin-uid" }
  let(:email) { "john.doe@email.pl" }

  before do
    allow(Mp::Variant).to receive_messages(pl?: pl, marketplace?: !pl)
    OmniAuth.config.add_mock(
      :checkin,
      uid: uid,
      info: { first_name: "John", last_name: "Doe", email: email },
      credentials: { token: "checkin-token" }
    )
    post user_checkin_omniauth_authorize_path
    follow_redirect!
  end

  context "when running as marketplace" do
    let(:pl) { false }

    it "creates the user through users.uid" do
      expect(User.find_by(uid: uid)).to have_attributes(email: email)
    end

    it "creates no identity" do
      expect(UserIdentity.count).to eq(0)
    end

    it "keeps the checkin token in the session" do
      expect(session["token"]).to eq("checkin-token")
    end
  end

  context "when running as pl" do
    let(:pl) { true }

    it "creates the user with a primary checkin identity" do
      expect(UserIdentity.find_by(provider: "checkin", uid: uid)).to have_attributes(primary: true)
    end

    it "leaves users.uid empty" do
      expect(User.find_by(email: email).read_attribute(:uid)).to be_nil
    end

    it "keeps no checkin token in the session" do
      expect(session["token"]).to be_nil
    end
  end
end
