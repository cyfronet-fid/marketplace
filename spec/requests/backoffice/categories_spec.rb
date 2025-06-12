# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice category", backend: true do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    it "I can delete category" do
      category = create(:category)

      expect { delete backoffice_other_settings_category_path(category) }.to change { Category.count }.by(-1)
    end
  end
end
