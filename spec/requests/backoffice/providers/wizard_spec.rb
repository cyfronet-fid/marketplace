# frozen_string_literal: true

require "rails_helper"

# pl and whitelabel offer "Save as draft" in the exit modal of the wizard;
# marketplace has no such button and refuses the request.
RSpec.describe "Backoffice: provider wizard", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:draft_params) { { provider: { name: "Draft provider" }, commit: "Save as draft" } }

  before { login_as(coordinator) }

  context "when running as pl" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: true, whitelabel?: false)
      get new_backoffice_provider_path
      put backoffice_provider_wizard_path("new"), params: draft_params
    end

    it "redirects to the providers list" do
      expect(response).to redirect_to(backoffice_providers_path(format: :html))
    end

    it "saves the provider as a draft" do
      expect(Provider.find_by(name: "Draft provider")).to be_draft
    end
  end

  # pl keeps only a known step for the partial render (pl-marketplace #129).
  context "when running as pl with an unknown step" do
    let(:provider) { create(:provider) }

    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: true, whitelabel?: false)
      get edit_backoffice_provider_path(provider)
      get backoffice_provider_wizard_path(provider, step: "../tabs/marketing")
    end

    it "renders the wizard" do
      expect(response).to have_http_status(:ok)
    end

    it "keeps the first step" do
      expect(session[:provider_step]).to eq("profile")
    end
  end

  context "when running as whitelabel" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true)
      get new_backoffice_provider_path
      put backoffice_provider_wizard_path("new"), params: draft_params
    end

    it "redirects to the providers list" do
      expect(response).to redirect_to(backoffice_providers_path(format: :html))
    end

    it "saves the provider as a draft" do
      expect(Provider.find_by(name: "Draft provider")).to be_draft
    end
  end

  context "when running as marketplace" do
    before do
      allow(Mp::Variant).to receive_messages(marketplace?: true, pl?: false, whitelabel?: false)
      get new_backoffice_provider_path
      put backoffice_provider_wizard_path("new"), params: draft_params
    end

    it "refuses the draft" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates no provider" do
      expect(Provider.find_by(name: "Draft provider")).to be_nil
    end
  end
end
