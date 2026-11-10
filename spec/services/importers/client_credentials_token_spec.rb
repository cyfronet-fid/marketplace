# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::ClientCredentialsToken, :backend do
  subject(:token_importer) { described_class.new }

  let(:endpoint) { "https://checkin.example/token" }

  around do |example|
    keys = %w[CHECKIN_HOST CHECKIN_TOKEN_ENDPOINT IMPORT_CLIENT_ID IMPORT_CLIENT_SECRET]
    original = keys.index_with { |key| ENV.key?(key) ? ENV[key] : nil }

    ENV.delete("CHECKIN_HOST")
    ENV["CHECKIN_TOKEN_ENDPOINT"] = endpoint
    ENV["IMPORT_CLIENT_ID"] = "import-client"
    ENV["IMPORT_CLIENT_SECRET"] = "import-secret"
    example.run
  ensure
    keys.each { |key| original[key].nil? ? ENV.delete(key) : ENV[key] = original[key] }
  end

  before { allow(Mp::Variant).to receive(:whitelabel?).and_return(false) }

  it "requests an access token with client credentials" do
    stub_request(:post, endpoint).with(
      body: {
        grant_type: "client_credentials",
        client_id: "import-client",
        client_secret: "import-secret"
      },
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded"
      }
    ).to_return(status: 200, body: { access_token: "received-token" }.to_json)

    expect(token_importer.receive_token).to eq("received-token")
  end

  it "rejects partial credentials" do
    ENV.delete("IMPORT_CLIENT_SECRET")

    expect { token_importer.receive_token }.to raise_error(
      described_class::ConfigurationError,
      "Missing import client credentials: IMPORT_CLIENT_SECRET"
    )
  end

  it "builds a URL from a Check-in host and relative endpoint" do
    ENV["CHECKIN_HOST"] = "checkin.example"
    ENV["CHECKIN_TOKEN_ENDPOINT"] = "realms/core/protocol/openid-connect/token"
    endpoint = "https://checkin.example/auth/realms/core/protocol/openid-connect/token"
    stub_request(:post, endpoint).to_return(status: 200, body: { access_token: "received-token" }.to_json)

    expect(token_importer.receive_token).to eq("received-token")
  end

  context "when whitelabel discovers the Check-in token endpoint" do
    let(:issuer) { "https://keycloak.example/realms/core" }
    let(:discovered_endpoint) { "https://keycloak.example/realms/core/protocol/openid-connect/token" }
    let(:oidc_config) do
      instance_double(OpenIDConnect::Discovery::Provider::Config::Response, token_endpoint: discovered_endpoint)
    end
    let(:received_token) { token_importer.receive_token }

    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Devise.omniauth_configs[:checkin]).to receive(:options).and_return(
        discovery: true,
        issuer: issuer,
        client_options: {
          scheme: "https",
          host: "keycloak.example",
          port: nil,
          token_endpoint: "/token"
        }
      )
      allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!).with(issuer).and_return(oidc_config)
      stub_request(:post, discovered_endpoint).with(
        body: {
          grant_type: "client_credentials",
          client_id: "import-client",
          client_secret: "import-secret"
        }
      ).to_return(status: 200, body: { access_token: "discovered-token" }.to_json)
    end

    it "requests the token from the discovered endpoint" do
      expect(received_token).to eq("discovered-token")
    end
  end

  context "when whitelabel has Check-in discovery switched off" do
    let(:issuer) { "https://keycloak.example/realms/core" }
    let(:received_token) { token_importer.receive_token }

    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Devise.omniauth_configs[:checkin]).to receive(:options).and_return(
        discovery: false,
        issuer: issuer,
        client_options: {
          scheme: "https",
          host: "keycloak.example",
          port: nil,
          token_endpoint: "/token"
        }
      )
      allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
      stub_request(:post, "https://keycloak.example/token").to_return(
        status: 200,
        body: { access_token: "configured-token" }.to_json
      )
    end

    it "requests the token from the configured endpoint" do
      expect(received_token).to eq("configured-token")
    end

    it "does not run discovery" do
      received_token

      expect(OpenIDConnect::Discovery::Provider::Config).not_to have_received(:discover!)
    end
  end

  context "when whitelabel has no import client secret" do
    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Devise.omniauth_configs[:checkin]).to receive(:options).and_return(
        discovery: false,
        issuer: "https://keycloak.example/realms/core",
        client_options: {
          scheme: "https",
          host: "keycloak.example",
          port: nil,
          token_endpoint: "/token"
        }
      )
      ENV.delete("IMPORT_CLIENT_SECRET")
    end

    it "raises a key error instead of a configuration error" do
      expect { token_importer.receive_token }.to raise_error(KeyError)
    end
  end
end
