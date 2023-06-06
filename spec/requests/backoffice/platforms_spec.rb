# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: platforms", backend: true do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { login_as(user) }

    it "I can delete platform" do
      platfrom = create(:platform)

      expect { delete backoffice_platform_path(platfrom) }.to change { Platform.count }.by(-1)
    end
  end
end
