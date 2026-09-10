# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Services::ChooseOffersController functionality", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:service_category) { create(:service_category) }
  let(:service_resource) { create(:service, resource_organisation: provider, status: :published) }

  before { sign_in(user) }

  describe "#check_vo_membership!" do
    before { allow(Checkin::CheckVoMembership).to receive(:call).and_return(check_vo_membership_result) }

    context "when the status is misconfiguration" do
      let(:check_vo_membership_result) { Checkin::CheckVoMembership::Result.new(status: :misconfiguration) }

      before { get service_choose_offer_path(service_resource) }

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end

      it "sets a misconfiguration alert" do
        expect(flash[:alert]).to eq("We can't verify your VO membership. Please contact admin.")
      end
    end

    context "when the status is session_expired" do
      let(:check_vo_membership_result) { Checkin::CheckVoMembership::Result.new(status: :session_expired) }

      before { get service_choose_offer_path(service_resource) }

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end

      it "sets an expired session alert" do
        expect(flash[:alert]).to eq("Your session has expired. Please sign in again.")
      end

      it "signs the user out" do
        get service_choose_offer_path(service_resource)
        expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
      end
    end

    context "when the status is verification_failed" do
      let(:check_vo_membership_result) { Checkin::CheckVoMembership::Result.new(status: :verification_failed) }

      before { get service_choose_offer_path(service_resource) }

      it "redirects to root" do
        expect(response).to redirect_to(root_path)
      end

      it "sets a verification failure alert" do
        expect(flash[:alert]).to eq("Your VO membership verification has failed.")
      end
    end

    context "when the status is not_member" do
      let(:check_vo_membership_result) do
        Checkin::CheckVoMembership::Result.new(status: :not_member, become_vo_member_url: "https://example.com/enroll")
      end

      before { get service_choose_offer_path(service_resource) }

      it "redirects to the become_vo_member_url" do
        expect(response).to redirect_to("https://example.com/enroll")
      end
    end

    context "when the status is member" do
      let(:check_vo_membership_result) { Checkin::CheckVoMembership::Result.new(status: :member) }

      before do
        create(
          :offer,
          service: service_resource,
          deployable_service: nil,
          offer_category: service_category,
          status: :published
        )
        create(
          :offer,
          service: service_resource,
          deployable_service: nil,
          offer_category: service_category,
          name: "Alternative Offer",
          status: :published
        )
      end

      it "proceeds to the requested action" do
        get service_choose_offer_path(service_resource)
        expect(response).to have_http_status(:success)
      end
    end

    context "when the service returns refreshed tokens" do
      let(:check_vo_membership_result) do
        Checkin::CheckVoMembership::Result.new(
          status: :verification_failed,
          refresh_token: "new-refresh",
          access_token: "new-token"
        )
      end

      before { get service_choose_offer_path(service_resource) }

      it "syncs the refreshed tokens into the session before redirecting" do
        expect(session.to_h).to include("token" => "new-token", "refresh_token" => "new-refresh")
      end
    end
  end
end
