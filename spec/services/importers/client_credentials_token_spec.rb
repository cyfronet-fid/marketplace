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
end
