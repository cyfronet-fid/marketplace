# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service", backend: true do
  include OmniauthHelper
  include ExternalServiceDataHelper

  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    it "I can delete service" do
      service = create(:service, status: :draft)

      delete backoffice_service_path(service)
      expect(service.reload.status).to eq "deleted"
    end

    it "I can publish service" do
      service = create(:service, status: :draft)

      post backoffice_service_publish_path(service)
      service.reload

      expect(service).to be_published
    end

    it "I can change service status to unpublished" do
      service = create(:service, status: :published)

      post backoffice_service_draft_path(service)
      service.reload

      expect(service).to be_unpublished
    end

    it "I can't publish a service with deleted status" do
      service = create(:service, status: :deleted)

      post backoffice_service_publish_path(service)
      expect(response).to redirect_to root_path(anchor: "")
      expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
    end

    it "I can't change status to a service with deleted status" do
      service = create(:service, status: :deleted)

      post backoffice_service_draft_path(service)
      expect(response).to redirect_to root_path(anchor: "")
      expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
    end
  end
end
