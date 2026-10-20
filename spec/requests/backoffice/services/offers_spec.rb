# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: edit an offer", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service, name: "Old name") }

  before do
    login_as(coordinator)
    patch backoffice_service_offer_path(service, offer.iid), params: params
  end

  context "when the offer is updated" do
    let(:params) { { offer: { name: "New name" }, commit: "Update Offer" } }

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "renames the offer" do
      expect(offer.reload.name).to eq("New name")
    end

    it "keeps the offer on its service" do
      expect(offer.reload.orderable).to eq(service)
    end
  end

  context "when the offer is saved as a draft" do
    let(:params) { { offer: { name: "Ignored" }, name: "Draft name", commit: "Save as draft" } }

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "drafts the offer" do
      expect(offer.reload).to be_draft
    end

    it "takes the name of the draft" do
      expect(offer.reload.name).to eq("Draft name")
    end
  end
end
