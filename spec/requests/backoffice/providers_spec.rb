# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: manage providers" do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { login_as(user) }

    it "I can delete provider" do
      category = create(:provider)

      expect { delete backoffice_provider_path(category) }.
        to change { Provider.count }.by(-1)
    end

    it "should call permitted_attributes with provider with form upstream_id" do
      provider = create(:provider)
      new_params = {
        name: "test1111111",
        abbreviation: "test 111111"
      }
      put backoffice_provider_path(provider), params: { provider: { upstream_id: nil, **new_params } }

      provider.reload
      expect(provider.upstream_id).to eq(nil)
      new_params.each { |key, value| expect(provider[key]).to eq(value) }
    end
  end
end
