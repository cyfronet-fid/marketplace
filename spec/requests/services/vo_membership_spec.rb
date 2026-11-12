# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order flow Checkin VO membership check", type: :request do
  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service) }

  # Deployable service pages are routed only under marketplace.
  context "when a marketplace session has no Checkin token and the user deploys a deployable service",
          variant: :marketplace do
    let(:deployable_service) { create(:deployable_service) }
    let(:offer) { create(:offer, service: nil, deployable_service: deployable_service) }

    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(true)
      offer
      sign_in(user)
      get deployable_service_choose_offer_path(deployable_service)
    end

    it "sends the signed-in user through Checkin again" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end
  end

  context "when a marketplace session has no Checkin token and the user orders a service" do
    before do
      allow(Mp::Variant).to receive(:marketplace?).and_return(true)
      offer
      sign_in(user)
      get service_choose_offer_path(service)
    end

    it "does not ask for a Checkin token" do
      expect(response).to redirect_to(service_information_path(service))
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
