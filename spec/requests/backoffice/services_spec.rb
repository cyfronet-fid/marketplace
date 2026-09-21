# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service", :backend do
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
      service = create(:service, owners: [user], status: :draft)

      post backoffice_service_publish_path(service)
      service.reload

      expect(service).to be_published
    end

    it "I can change service status to unpublished" do
      service = create(:service, owners: [user])

      post backoffice_service_draft_path(service)
      service.reload

      expect(service).to be_unpublished
    end

    it "I can't publish a service with deleted status" do
      service = create(:service, owners: [user], status: :deleted)

      post backoffice_service_publish_path(service)
      expect(response).to redirect_to root_path(anchor: "")
      expect(flash[:alert]).to eq(I18n.t("pundit.default"))
    end

    it "I can't change status to a service with deleted status" do
      service = create(:service, owners: [user], status: :deleted)

      post backoffice_service_draft_path(service)
      expect(response).to redirect_to root_path(anchor: "")
      expect(flash[:alert]).to eq(I18n.t("pundit.default"))
    end

    context "when accessing Backoffice services" do
      before { get backoffice_services_path }

      it "allows access" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "when accessing Backoffice services under pl" do
      before do
        allow(Mp::Variant).to receive(:pl?).and_return(true)
        get backoffice_services_path
      end

      it "allows access" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when logged in without Backoffice permissions" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      get backoffice_services_path
    end

    it "redirects to the root page" do
      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert" do
      expect(flash[:alert]).to eq(I18n.t("pundit.default"))
    end
  end

  context "when logged in without Backoffice permissions under pl" do
    let(:user) { create(:user) }

    before do
      allow(Mp::Variant).to receive(:pl?).and_return(true)
      login_as(user)
      get backoffice_services_path
    end

    it "redirects to the root page" do
      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert" do
      expect(flash[:alert]).to eq(I18n.t("pundit.default"))
    end
  end
end
