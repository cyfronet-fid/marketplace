# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service" do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { login_as(user) }

    it "I can delete service when there is no project_items yet" do
      service = create(:service)

      expect { delete backoffice_service_path(service) }.
        to change { Service.count }.by(-1)
    end
  end
end
