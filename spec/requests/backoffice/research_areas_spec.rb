# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice research area" do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { login_as(user) }

    it "I can delete research area" do
      research_area = create(:research_area)

      expect { delete backoffice_research_area_path(research_area) }.
        to change { ResearchArea.count }.by(-1)
    end
  end
end
