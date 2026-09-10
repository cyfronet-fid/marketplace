# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkin::Client, type: :service do
  subject(:client) { described_class.new }

  let(:issuer) { "https://checkin.example.com/realms/core" }
  let(:identifier) { "client-id" }
  let(:secret) { "client-secret" }

  before do
    provider = instance_double(
      Devise::OmniAuth::Config,
      options: {
        issuer: issuer,
        client_options: {
          identifier: identifier,
          secret: secret
        }
      }
    )

    allow(Devise.omniauth_configs).to receive(:[]).with(:checkin).and_return(provider)

    stub_request(:get, "#{issuer}/.well-known/openid-configuration").to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        issuer: issuer,
        authorization_endpoint: "#{issuer}/authorize",
        token_endpoint: "#{issuer}/token",
        introspection_endpoint: "#{issuer}/token/introspect",
        userinfo_endpoint: "#{issuer}/userinfo",
        jwks_uri: "#{issuer}/jwk",
        response_types_supported: ["code"],
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["RS256"]
      }.to_json
    )
  end

  describe "#introspect" do
    subject(:response) { client.introspect(access_token) }

    let(:access_token) { "a-token" }

    before do
      stub_request(:post, "#{issuer}/token/introspect")
        .with(
          body: "token=#{access_token}",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        )
        .to_return(status: 200, body: { active: true }.to_json)
    end

    it "returns the introspection response" do
      expect(response.status).to eq(200)
    end

    it "returns the introspection response body" do
      expect(JSON.parse(response.body)).to eq("active" => true)
    end

    it "authenticates with HTTP basic auth using the checkin client credentials" do
      response

      expect(WebMock)
        .to have_requested(:post, "#{issuer}/token/introspect")
        .with(headers: { "Authorization" => "Basic #{Base64.strict_encode64("#{identifier}:#{secret}")}" })
    end
  end

  describe "#refresh_token" do
    subject(:response) { client.refresh_token(refresh_token) }

    let(:refresh_token) { "a-refresh-token" }

    before do
      stub_request(:post, "#{issuer}/token")
        .with(
          body: "grant_type=refresh_token&refresh_token=#{refresh_token}",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        )
        .to_return(status: 200, body: { access_token: "new-token", refresh_token: "new-refresh" }.to_json)
    end

    it "returns the token refresh response" do
      expect(response.status).to eq(200)
    end

    it "returns the refreshed tokens in the response body" do
      expect(JSON.parse(response.body)).to eq("access_token" => "new-token", "refresh_token" => "new-refresh")
    end

    it "authenticates with HTTP basic auth using the checkin client credentials" do
      response

      expect(WebMock)
        .to have_requested(:post, "#{issuer}/token")
        .with(headers: { "Authorization" => "Basic #{Base64.strict_encode64("#{identifier}:#{secret}")}" })
    end
  end

  describe "timeouts" do
    context "with default options" do
      it "uses a 10 second request timeout" do
        expect(client.send(:timeout)).to eq(10)
      end

      it "uses a 5 second open timeout" do
        expect(client.send(:open_timeout)).to eq(5)
      end
    end

    context "with custom options" do
      subject(:client) { described_class.new(timeout: 1, open_timeout: 2) }

      it "uses the given request timeout" do
        expect(client.send(:timeout)).to eq(1)
      end

      it "uses the given open timeout" do
        expect(client.send(:open_timeout)).to eq(2)
      end
    end
  end
end
