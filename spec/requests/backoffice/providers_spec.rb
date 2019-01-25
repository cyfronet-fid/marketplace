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
  end
end
