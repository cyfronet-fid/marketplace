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

    # pl's provider tabs post no provider fields when the tab has none to
    # show, for example the managers tab of a provider without data administrators.
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

    # An invalid update renders the full edit page again. The edit template
    # must pass the tab local to the form, or the render raises a NameError.
    describe "PATCH /backoffice/providers/:id with an invalid value" do
      let(:provider) { create(:provider, name: "Unchanged") }

      before { patch backoffice_provider_path(provider), params: { provider: { name: "" } } }

      it "answers with the edit page" do
        expect(response).to have_http_status(:bad_request)
      end

      it "marks the profile tab as active" do
        expect(response.body).to include("profile-tab")
      end

      it "keeps the provider as it is" do
        expect(provider.reload.name).to eq("Unchanged")
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

    context "when listing providers under pl" do
      let(:deleted_provider) { create(:provider, name: "Removed provider", status: :deleted) }
      let(:listed_provider) { create(:provider, name: "Listed provider") }

      before do
        allow(Mp::Variant).to receive(:pl?).and_return(true)
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

    context "when listing providers under another variant" do
      let(:deleted_provider) { create(:provider, name: "Removed provider", status: :deleted) }

      before do
        allow(Mp::Variant).to receive(:pl?).and_return(false)
        deleted_provider
        get backoffice_providers_path
      end

      it "lists the deleted provider" do
        expect(response.body).to include("Removed provider")
      end
    end
  end
end
