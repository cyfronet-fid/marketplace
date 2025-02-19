# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: manage providers", backend: true do
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

    it "I can delete provider having service with status different than deleted" do
      provider = create(:provider)
      create(:service, status: :errored, resource_organisation: provider)

      expect { delete backoffice_provider_path(provider) }.to change { Provider.where.not(status: :deleted).count }.by(
        -1
      )

      provider = create(:provider)
      create(:service, status: :draft, resource_organisation: provider)

      expect { delete backoffice_provider_path(provider) }.to change { Provider.where.not(status: :deleted).count }.by(
        -1
      )
    end

    it "should call permitted_attributes with provider with form upstream_id" do
      provider = create(:provider)

      new_params = { name: "test1111111", abbreviation: "test 111111" }
      put backoffice_provider_path(provider), params: { provider: { upstream_id: nil, **new_params } }

      provider.reload
      expect(provider.upstream_id).to eq(nil)
      new_params.each { |key, value| expect(provider[key]).to eq(value) }
    end
  end
end
