# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::CheckVoMembership, type: :service do
  subject(:result) do
    described_class.call(
      token: token,
      refresh_token: "a-refresh-token",
      checkin_config: checkin_config,
      introspect_service: introspect_service,
      refresh_service: refresh_service
    )
  end

  let(:introspect_service) { class_double(Users::IntrospectAccessToken) }
  let(:refresh_service) { class_double(Users::RefreshAccessToken) }
  let(:checkin_config) { class_double(Users::CheckinConfig, vo_group_name: "eosc-beyond.eu", become_vo_member_url: "https://example.com/enroll") }

  describe "when the token is blank" do
    let(:token) { "" }

    before { allow(introspect_service).to receive(:call) }

    it "returns a session_expired status" do
      expect(result.status).to eq(:session_expired)
    end

    it "does not call the introspection service" do
      result
      expect(introspect_service).not_to have_received(:call)
    end
  end

  describe "when introspection fails" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: false))
    end

    it "returns a verification_failed status" do
      expect(result.status).to eq(:verification_failed)
    end
  end

  describe "when the token is active and the user is a VO member" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: true, entitlements: ["group:eosc-beyond.eu"]))
    end

    it "returns a member status" do
      expect(result.status).to eq(:member)
    end
  end

  describe "when the token is inactive and refresh fails" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: false))

      allow(refresh_service)
        .to receive(:call)
        .with("a-refresh-token")
        .and_return(double(success: false))
    end

    it "returns a session_expired status" do
      expect(result.status).to eq(:session_expired)
    end
  end

  describe "when the token is inactive, refresh succeeds, but re-introspection fails" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: false))

      allow(refresh_service)
        .to receive(:call)
        .with("a-refresh-token")
        .and_return(double(success: true, access_token: "new-token", refresh_token: "new-refresh"))

      allow(introspect_service)
        .to receive(:call)
        .with("new-token")
        .and_return(double(success: false))
    end

    it "returns a verification_failed status" do
      expect(result.status).to eq(:verification_failed)
    end
  end

  describe "when the token is inactive, refresh succeeds, and re-introspection confirms membership" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: false))

      allow(refresh_service)
        .to receive(:call)
        .with("a-refresh-token")
        .and_return(double(success: true, access_token: "new-token",
                           refresh_token: "new-refresh"))

      allow(introspect_service)
        .to receive(:call)
        .with("new-token")
        .and_return(double(success: true, active: true, entitlements: ["group:eosc-beyond.eu"]))
    end

    it "returns a member status carrying the refreshed tokens" do
      expect(result).to have_attributes(status: :member, access_token: "new-token", refresh_token: "new-refresh")
    end
  end

  describe "when the token is active but the user lacks the VO entitlement, and a become_vo_member_url is configured" do
    let(:token) { "a-token" }

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: true, entitlements: []))
    end

    it "returns a not_member status carrying the become_vo_member_url" do
      expect(result).to have_attributes(status: :not_member, become_vo_member_url: "https://example.com/enroll")
    end
  end

  describe "when the token is active, the user lacks the VO entitlement, and no become_vo_member_url is configured" do
    let(:token) { "a-token" }

    let(:checkin_config) do
      class_double(
        Users::CheckinConfig,
        vo_group_name: "eosc-beyond.eu",
        become_vo_member_url: nil
      )
    end

    before do
      allow(introspect_service)
        .to receive(:call)
        .with(token)
        .and_return(double(success: true, active: true, entitlements: []))
    end

    it "returns a vo_url_missing status" do
      expect(result.status).to eq(:vo_url_missing)
    end
  end
end
