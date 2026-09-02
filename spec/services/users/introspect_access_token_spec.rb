# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::IntrospectAccessToken, type: :service do
  subject(:result) { described_class.call(token, client_options: client_options) }

  let(:token) { "access-token-123" }
  let(:introspection_url) { "https://aai.eosc-portal.eu/introspect" }
  let(:client_options) do
    { identifier: "client-id", secret: "client-secret", introspection_uri: introspection_url }
  end

  describe "when introspection succeeds and the token is active" do
    before do
      stub_request(:post, introspection_url).with(
        basic_auth: %w[client-id client-secret],
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: "token=#{token}"
      ).to_return(
        status: 200,
        body: { active: true, entitlements: ["group:eosc-beyond.eu"] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "returns a successful, active result with the entitlements" do
      expect(result).to have_attributes(success: true, active: true, entitlements: ["group:eosc-beyond.eu"])
    end
  end

  describe "when introspection succeeds and the token is inactive" do
    before do
      stub_request(:post, introspection_url).to_return(
        status: 200,
        body: { active: false }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "returns a successful, inactive result" do
      expect(result).to have_attributes(success: true, active: false)
    end
  end

  describe "when the introspection endpoint returns an HTTP error" do
    before { stub_request(:post, introspection_url).to_return(status: 401, body: "unauthorized") }

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end
  end

  describe "when the introspection endpoint returns malformed JSON" do
    before do
      stub_request(:post, introspection_url).to_return(
        status: 200,
        body: "not json",
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end
  end

  describe "when the request fails at the network level" do
    before { stub_request(:post, introspection_url).to_raise(Faraday::ConnectionFailed) }

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end
  end
end
