# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::RefreshAccessToken, type: :service do
  subject(:result) { described_class.call(refresh_token, client_options: client_options) }

  let(:refresh_token) { "refresh-token-123" }
  let(:token_url) { "https://aai.eosc-portal.eu/token" }
  let(:client_options) do
    { identifier: "client-id", secret: "client-secret", scheme: "https", host: "aai.eosc-portal.eu", port: nil,
      token_endpoint: "/token" }
  end

  describe "when the refresh token is blank" do
    let(:refresh_token) { "" }

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end

    it "does not make a request" do
      result
      expect(WebMock).not_to have_requested(:post, token_url)
    end
  end

  describe "when the refresh succeeds" do
    before do
      stub_request(:post, token_url).with(
        basic_auth: %w[client-id client-secret],
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: "grant_type=refresh_token&refresh_token=#{refresh_token}"
      ).to_return(
        status: 200,
        body: { access_token: "new-access-token", refresh_token: "new-refresh-token" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "returns a successful result with the new tokens" do
      expect(result).to have_attributes(success: true, access_token: "new-access-token",
                                        refresh_token: "new-refresh-token")
    end
  end

  describe "when the token endpoint returns an HTTP error" do
    before { stub_request(:post, token_url).to_return(status: 400, body: "bad request") }

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end
  end

  describe "when the token endpoint returns malformed JSON" do
    before do
      stub_request(:post, token_url).to_return(
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
    before { stub_request(:post, token_url).to_raise(Faraday::ConnectionFailed) }

    it "returns an unsuccessful result" do
      expect(result.success).to be false
    end
  end
end
