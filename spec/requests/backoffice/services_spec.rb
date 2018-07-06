# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service" do
  context "as a logged in service owner" do
    let(:user) { create(:user, roles: [:service_owner]) }

    before { login_as(user) }

    it "I can delete owned service when there is no orders yet" do
      service = create(:service, owner: user)

      expect { delete backoffice_service_path(service) }.
        to change { user.owned_services.count }.by(-1)
    end
  end
end
