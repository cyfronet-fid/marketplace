# frozen_string_literal: true

require "rails_helper"

# The "Select an offer" link of each variant is a GET request to the offer selection step (#3857).
RSpec.describe "Select an offer", type: :request do
  let(:user) { create(:user) }
  let(:service) { create(:service, status: :published) }
  let(:offer) { create(:offer, service: service, status: :published) }
  let(:alternative_offer) { create(:offer, service: service, status: :published, name: "Alternative Offer") }
  let(:select_offer_path) { service_choose_offer_path(service, customizable_project_item: { offer_id: offer.iid }) }

  context "when the user is signed in" do
    before do
      alternative_offer
      sign_in(user)
      get select_offer_path
    end

    it "goes directly to the offer configuration" do
      expect(response).to redirect_to(service_information_path(service))
    end
  end

  context "when the user is not signed in" do
    before do
      alternative_offer
      get select_offer_path
    end

    it "sends the user to Check-in of the instance" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end
  end

  context "when the user signs in after the selection of an offer" do
    before do
      alternative_offer
      OmniAuth.config.add_mock(
        :checkin,
        uid: user.uid,
        info: { first_name: user.first_name, last_name: user.last_name, email: user.email },
        credentials: { token: "checkin-token", refresh_token: "checkin-refresh-token" }
      )
      get select_offer_path
      follow_redirect!
      follow_redirect!
    end

    it "returns the user to the selected offer" do
      expect(response).to redirect_to(select_offer_path)
    end
  end

  context "when the user who signed in after the selection of an offer returns to the selected offer" do
    before do
      alternative_offer
      OmniAuth.config.add_mock(
        :checkin,
        uid: user.uid,
        info: { first_name: user.first_name, last_name: user.last_name, email: user.email },
        credentials: { token: "checkin-token", refresh_token: "checkin-refresh-token" }
      )
      get select_offer_path
      follow_redirect!
      follow_redirect!
      follow_redirect!
    end

    it "goes to the offer configuration" do
      expect(response).to redirect_to(service_information_path(service))
    end
  end
end
