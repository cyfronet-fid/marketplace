# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: duplicate an offer", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service) }
  let(:copy) { service.offers.find_by(name: "Copy") }

  before do
    login_as(coordinator)
    post duplicate_offer_path(service, offer), params: { custom_form: { new_name: "Copy" } }
  end

  context "when the offer has an offer category" do
    let(:offer) { create(:offer, service: service, name: "Original") }

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "confirms the copy" do
      expect(flash[:notice]).to eq("Offer duplicated successfully")
    end

    it "saves the copy as a draft" do
      expect(copy).to be_draft
    end

    it "keeps the offer category in the copy" do
      expect(copy.offer_category).to eq(offer.offer_category)
    end

    it "keeps the original offer published" do
      expect(offer.reload).to be_published
    end
  end

  # The offers of whitelabel come from before the offer category became mandatory.
  context "when the offer has no offer category" do
    let(:offer) do
      build(:offer, service: service, name: "Original", offer_category: nil).tap { |offer| offer.save(validate: false) }
    end

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "confirms the copy" do
      expect(flash[:notice]).to eq("Offer duplicated successfully")
    end

    it "saves the copy as a draft" do
      expect(copy).to be_draft
    end

    it "keeps the copy on the service" do
      expect(copy.orderable).to eq(service)
    end
  end
end
