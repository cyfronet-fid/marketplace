# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: manage providers", :backend do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    context "I can delete provider" do
      it "without any service" do
        provider = create(:provider)

        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where.not(status: :deleted).count
        }.by(-1)
      end

      it "with all deleted services" do
        provider = create(:provider)
        create(:service, resource_organisation: provider, status: :deleted)

        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where.not(status: :deleted).count
        }.by(-1)
      end
    end

    # pl and whitelabel cascade the delete instead (Provider::Delete::Cascading).
    it "I can't delete provider having service with status different than deleted", variant: :marketplace do
      provider = create(:provider)
      create(:service, status: :errored, resource_organisation: provider)

      expect { delete backoffice_provider_path(provider) }.not_to change { Provider.where.not(status: :deleted).count }

      provider = create(:provider)
      create(:service, status: :draft, resource_organisation: provider)

      expect { delete backoffice_provider_path(provider) }.not_to change { Provider.where.not(status: :deleted).count }
    end

    it "calls permitted_attributes with provider with form upstream_id" do
      provider = create(:provider)

      new_params = { name: "test1111111", abbreviation: "test 111111" }
      put backoffice_provider_path(provider), params: { provider: { upstream_id: nil, **new_params } }

      provider.reload
      expect(provider.upstream_id).to be_nil
      new_params.each { |key, value| expect(provider[key]).to eq(value) }
    end

    # The tabs post no provider fields when the tab has none to show, for
    # example the managers tab of a provider without data administrators.
    describe "PATCH /backoffice/providers/:id without provider fields" do
      let(:provider) { create(:provider, name: "Unchanged") }

      before do
        patch backoffice_provider_path(provider),
              params: { tab: "managers" },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      it "answers with the updated provider" do
        expect(response).to have_http_status(:ok)
      end

      it "keeps the provider as it is" do
        expect(provider.reload.name).to eq("Unchanged")
      end
    end

    # An invalid update shows the errors in the submitted tab (pl-marketplace #129).
    describe "PATCH /backoffice/providers/:id with an invalid value" do
      let(:provider) { create(:provider, name: "Unchanged") }

      before do
        patch backoffice_provider_path(provider),
              params: { tab: "location", provider: { name: "" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      it "answers with unprocessable content" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "replaces the tab content" do
        expect(response.body).to include('<turbo-stream action="replace" target="tab_content">')
      end

      it "renders the submitted tab" do
        expect(response).to render_template(partial: "backoffice/providers/tabs/_location")
      end

      it "keeps the provider as it is" do
        expect(provider.reload.name).to eq("Unchanged")
      end
    end

    # The tabs are forms and need an empty row for each blank nested model.
    describe "GET /backoffice/providers/:id" do
      let(:provider) { create(:provider) }

      before do
        get backoffice_provider_path(provider, tab: "contacts"), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      it "builds an empty main contact" do
        expect(assigns(:provider).main_contact).to be_new_record
      end

      it "builds an empty public contact" do
        expect(assigns(:provider).public_contacts.map(&:new_record?)).to eq([true])
      end
    end

    # The tabs save in place, so edit always opens the wizard.
    describe "GET /backoffice/providers/:id/edit with a tab step" do
      let(:provider) { create(:provider) }

      before { get edit_backoffice_provider_path(provider, step: "classification") }

      it "opens the wizard" do
        expect(response).to redirect_to(backoffice_provider_wizard_path(provider))
      end

      it "starts the wizard at the first step" do
        expect(session[:provider_step]).to eq("profile")
      end
    end

    describe "GET /backoffice/providers/new with an unknown step" do
      before { get new_backoffice_provider_path(step: "../tabs/marketing") }

      it "starts the wizard at the first step" do
        expect(session[:provider_step]).to eq("profile")
      end
    end

    # There is no new page: the wizard shows the submitted values again.
    describe "POST /backoffice/providers with an invalid value" do
      before { post backoffice_providers_path, params: { provider: { name: "", abbreviation: "Kept" } } }

      it "opens the wizard" do
        expect(response).to redirect_to(backoffice_provider_wizard_path("new"))
      end

      it "keeps the submitted values for the wizard" do
        expect(session["new"]).to include("abbreviation" => "Kept")
      end
    end

    it "can save an in-progress wizard registration as a draft" do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      provider = create(:provider, status: :unpublished)
      get edit_backoffice_provider_path(provider)

      put backoffice_provider_wizard_path(provider),
          params: { provider: { name: provider.name }, commit: "Save as draft" }

      expect(response).to redirect_to(backoffice_providers_path(format: :html))
      expect(provider.reload.status).to eq("draft")
      expect(session[provider.id.to_s.to_sym]).to be_nil
    end

    it "does not expose save-as-draft behavior to marketplace" do
      allow(Mp::Variant).to receive_messages(marketplace?: true, pl?: false, whitelabel?: false)
      provider = create(:provider, status: :unpublished)
      get edit_backoffice_provider_path(provider)

      put backoffice_provider_wizard_path(provider),
          params: { provider: { name: provider.name }, commit: "Save as draft" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(provider.reload.status).to eq("unpublished")
    end

    # A deleted provider leaves the list (pl-marketplace #156).
    describe "GET /backoffice/providers" do
      let(:deleted_provider) { create(:provider, name: "Removed provider", status: :deleted) }
      let(:listed_provider) { create(:provider, name: "Listed provider") }

      before do
        deleted_provider
        listed_provider
        get backoffice_providers_path
      end

      it "hides the deleted provider" do
        expect(response.body).not_to include("Removed provider")
      end

      it "lists the other provider" do
        expect(response.body).to include("Listed provider")
      end
    end
  end
end
