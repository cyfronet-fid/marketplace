# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: duplicate an offer", :backend do
  let(:user) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service, name: "Original") }
  let(:new_name) { "Copy" }
  let(:copy) { service.offers.find_by(name: "Copy") }

  before do
    login_as(user)
    post duplicate_offer_path(service, offer), params: { custom_form: { new_name: new_name } }
  end

  context "when the offer has an offer category" do
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

  context "when the copy has no name" do
    let(:new_name) { "" }

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "gives the reason" do
      expect(flash[:alert]).to eq("Offer duplication errored: name can't be blank")
    end

    it "does not save a copy" do
      expect(service.offers.count).to eq(1)
    end
  end

  context "when the user is a data administrator of the provider of the service" do
    let(:user) { create(:user) }
    # The signed-in user object must see the provider: the reload reads the counter of its providers again.
    let(:service) do
      administrator = build(:data_administrator, email: user.email)
      provider = create(:provider, data_administrators: [administrator])
      create(:service, resource_organisation: provider).tap { user.reload }
    end

    it "confirms the copy" do
      expect(flash[:notice]).to eq("Offer duplicated successfully")
    end

    it "saves the copy as a draft" do
      expect(copy).to be_draft
    end
  end

  # An executive opens the backoffice, but does not manage the service.
  context "when the user does not manage the service" do
    let(:user) { create(:user, roles: [:executive]) }

    it "redirects to the root page" do
      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "does not save a copy" do
      expect(service.offers.count).to eq(1)
    end
  end
end
