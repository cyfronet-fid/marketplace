# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order flow Checkin VO membership check", type: :request do
  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service) }

  context "when a marketplace session has no Checkin token" do
    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(true)
      offer
      sign_in(user)
      get service_choose_offer_path(service)
    end

    it "sends the signed-in user through Checkin again" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end
  end

  context "when the variant is not marketplace" do
    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(false)
      offer
      sign_in(user)
      get service_choose_offer_path(service)
    end

    it "does not ask for a Checkin token" do
      expect(response).to redirect_to(service_information_path(service))
    end
  end
end
