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

    it "does not expose save-as-draft behavior to another variant" do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(false)
      provider = create(:provider, status: :unpublished)
      get edit_backoffice_provider_path(provider)

      put backoffice_provider_wizard_path(provider),
          params: { provider: { name: provider.name }, commit: "Save as draft" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(provider.reload.status).to eq("unpublished")
    end
  end
end
