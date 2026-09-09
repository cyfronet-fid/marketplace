# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkin::Client, type: :service do
  subject(:client) { described_class.new }

  let(:identifier) { "client-id" }
  let(:secret) { "client-secret" }
  let(:introspection_url) { "https://aai.eosc-portal.eu/auth/realms/core/protocol/openid-connect/token/introspect" }
  let(:token_url) { "https://aai.eosc-portal.eu/auth/realms/core/protocol/openid-connect/token" }

  before do
    allow(Checkin::Config).to receive_messages(
      introspection_url: introspection_url,
      token_url: token_url,
      client_options: {
        identifier: identifier,
        secret: secret
      }
    )
  end

  describe "#introspect" do
    subject(:response) { client.introspect(access_token) }

    let(:access_token) { "a-token" }

    before do
      stub_request(:post, introspection_url)
        .with(
          body: "token=#{access_token}",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        )
        .to_return(
          status: 200,
          body: { active: true }.to_json
        )
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
        .to have_requested(:post, introspection_url)
        .with(headers: { "Authorization" => "Basic #{Base64.strict_encode64("#{identifier}:#{secret}")}" })
    end
  end

  describe "#refresh_token" do
    subject(:response) { client.refresh_token(refresh_token) }

    let(:refresh_token) { "a-refresh-token" }

    before do
      stub_request(:post, token_url)
        .with(
          body: "grant_type=refresh_token&refresh_token=#{refresh_token}",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        )
        .to_return(
          status: 200,
          body: { access_token: "new-token", refresh_token: "new-refresh" }.to_json
        )
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
        .to have_requested(:post, token_url)
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
