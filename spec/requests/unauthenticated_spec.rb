# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", :backend do
  it "is redirected to checkin" do
    get profile_path

    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
  end

  it "is not redirected if accessing root_path" do
    get root_path

    expect(response.status).to eq(200)
  end

  context "when accessing Backoffice services under pl" do
    before do
      allow(Mp::Variant).to receive(:pl?).and_return(true)
      get backoffice_services_path
    end

    it "redirects to Check-In" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end

    it "preserves the requested Backoffice page" do
      expect(request.session["user_return_to"]).to eq(backoffice_services_path)
    end
  end

  context "when accessing Backoffice services under another variant" do
    before do
      allow(Mp::Variant).to receive(:pl?).and_return(false)
      get backoffice_services_path
    end

    it "redirects to the root page" do
      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert" do
      expect(flash[:alert]).to eq(I18n.t("pundit.default"))
    end
  end
end
