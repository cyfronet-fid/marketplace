# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: save a new offer as a draft", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service) }
  let(:params) do
    {
      offer: {
        description: "Draft description",
        order_type: "open_access"
      },
      name: name,
      save_as_draft: "Save as draft"
    }
  end

  before do
    login_as(coordinator)
    post backoffice_service_offers_path(service), params: params
  end

  context "when the draft has a name" do
    let(:name) { "Draft name" }

    it "redirects to the offers of the service" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end

    it "saves the draft" do
      expect(service.offers.find_by(name: "Draft name")).to be_draft
    end
  end

  context "when the draft has no name" do
    let(:name) { "" }

    it "shows the form again" do
      expect(response).to have_http_status(:bad_request)
    end

    it "does not save the draft" do
      expect(service.offers.count).to eq(0)
    end
  end
end
