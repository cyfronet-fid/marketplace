# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: platforms", backend: true do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    it "I can delete platform" do
      platform = create(:platform)

      expect { delete backoffice_other_settings_platform_path(platform) }.to change { Platform.count }.by(-1)
    end
  end
end
