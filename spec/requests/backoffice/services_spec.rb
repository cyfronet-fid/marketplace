# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service" do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }

    before { login_as(user) }

    it "I can delete service when there is no project_items yet" do
      service = create(:service, status: :draft)

      expect { delete backoffice_service_path(service) }.
        to change { Service.count }.by(-1)
    end

    it "I can publish service" do
      service = create(:service, owners: [user], status: :draft)

      post backoffice_service_publish_path(service)
      service.reload

      expect(service).to be_published
    end

    it "I can change service status to draft" do
      service = create(:service, owners: [user])

      post backoffice_service_draft_path(service)
      service.reload

      expect(service).to be_draft
    end
  end
end
