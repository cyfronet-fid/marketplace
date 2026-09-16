# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::Services::UnpublishesController, type: :request do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:service) { create(:service, status: :published) }

  before do
    allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true)
    Rails.application.reload_routes!
    login_as(coordinator)
    post backoffice_service_unpublish_path(service), params: params
  end

  after do
    allow(Mp::Variant).to receive(:whitelabel?).and_call_original
    Rails.application.reload_routes!
  end

  context "without the suspend flag" do
    let(:params) { {} }

    it "unpublishes the service" do
      expect(service.reload).to be_unpublished
    end

    it "redirects to the service offers" do
      expect(response).to redirect_to(backoffice_service_offers_path(service))
    end
  end

  context "with the suspend flag" do
    let(:params) { { suspend: true } }

    it "suspends the service" do
      expect(service.reload).to be_suspended
    end
  end
end
