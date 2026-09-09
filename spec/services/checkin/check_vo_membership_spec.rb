# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkin::CheckVoMembership, type: :service do
  subject(:result) { described_class.call(access_token: access_token, refresh_token: refresh_token) }

  let(:access_token) { "a-token" }
  let(:refresh_token) { "a-refresh-token" }
  let(:new_access_token) { "new-token" }
  let(:new_refresh_token) { "new-refresh-token" }
  let(:client) { instance_double(Checkin::Client) }

  before do
    allow(Checkin::Client).to receive(:new).and_return(client)
    allow(Checkin::Config).to receive(:vo_group_name).and_return("eosc-beyond.eu")
  end

  context "when the refresh_token is blank" do
    let(:refresh_token) { "" }

    before do
      allow(Checkin::Logger).to receive(:warn)
      allow(client).to receive(:refresh_token)
    end

    it "returns a session_expired status" do
      expect(result.status).to eq(:session_expired)
    end

    it "does not call the refresh endpoint" do
      result
      expect(client).not_to have_received(:refresh_token)
    end

    it "logs a warning" do
      result
      expect(Checkin::Logger).to have_received(:warn).with("Missing credentials")
    end
  end

  context "when the refresh request fails" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(Faraday::Response, success?: false)
      )
    end

    it "returns a session_expired status" do
      expect(result.status).to eq(:session_expired)
    end
  end

  context "when refresh succeeds and the new token is active" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { access_token: new_access_token, refresh_token: new_refresh_token }.to_json
        )
      )

      allow(client).to receive(:introspect).with(new_access_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { active: true, entitlements: ["group:eosc-beyond.eu"] }.to_json
        )
      )
    end

    it "returns a member status using the refreshed tokens" do
      expect(result).to have_attributes(
        status: :member,
        access_token: new_access_token,
        refresh_token: new_refresh_token
      )
    end
  end

  context "when refresh succeeds and the new token is active but the user is not a VO member" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { access_token: new_access_token, refresh_token: new_refresh_token }.to_json
        )
      )

      allow(client).to receive(:introspect).with(new_access_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { active: true, entitlements: [] }.to_json
        )
      )
    end

    it "returns a not_member status" do
      expect(result.status).to eq(:not_member)
    end
  end

  context "when the refresh response omits new tokens" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(Faraday::Response, success?: true, body: {}.to_json)
      )

      allow(client).to receive(:introspect).with(access_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { active: true, entitlements: ["group:eosc-beyond.eu"] }.to_json
        )
      )
    end

    it "falls back to introspecting the original tokens" do
      result
      expect(client).to have_received(:introspect).with(access_token)
    end

    it "returns the original tokens" do
      expect(result).to have_attributes(access_token: access_token, refresh_token: refresh_token)
    end
  end

  context "when refresh succeeds but introspection reports the token inactive" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { access_token: new_access_token, refresh_token: new_refresh_token }.to_json
        )
      )

      allow(client).to receive(:introspect).with(new_access_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { active: false }.to_json
        )
      )
    end

    it "returns a session_expired status" do
      expect(result.status).to eq(:session_expired)
    end
  end

  context "when refresh succeeds but introspection fails outright" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(
          Faraday::Response,
          success?: true,
          body: { access_token: new_access_token, refresh_token: new_refresh_token }.to_json
        )
      )

      allow(client).to receive(:introspect).with(new_access_token).and_return(
        instance_double(Faraday::Response, success?: false)
      )
    end

    it "returns a verification_failed status" do
      expect(result.status).to eq(:verification_failed)
    end

    it "returns the refreshed tokens so they are persisted" do
      expect(result).to have_attributes(access_token: new_access_token, refresh_token: new_refresh_token)
    end
  end

  context "when the client raises a Faraday error" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_raise(
        Faraday::ConnectionFailed.new("connection failed")
      )
    end

    it "returns a verification_failed status" do
      expect(result.status).to eq(:verification_failed)
    end
  end

  context "when the response body is not valid JSON" do
    before do
      allow(client).to receive(:refresh_token).with(refresh_token).and_return(
        instance_double(Faraday::Response, success?: true, body: "not json")
      )
    end

    it "returns a verification_failed status" do
      expect(result.status).to eq(:verification_failed)
    end
  end
end
