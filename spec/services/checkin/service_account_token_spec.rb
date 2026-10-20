# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkin::ServiceAccountToken, type: :service do
  let(:token_url) { "https://aai.egi.eu/auth/realms/egi/protocol/openid-connect/token" }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:env) { {} }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    stub_const("ENV", ENV.to_h.except("EGI_ACCESS_TOKEN", "EGI_REFRESH_ACCESS_TOKEN").merge(env))
  end

  context "when a token is cached" do
    before { cache.write("egi_access_token", "cached-token") }

    let(:env) { { "EGI_ACCESS_TOKEN" => "env-token" } }

    it "returns the cached token" do
      expect(described_class.call).to eq("cached-token")
    end
  end

  context "when EGI_ACCESS_TOKEN is set" do
    let(:env) { { "EGI_ACCESS_TOKEN" => "env-token", "EGI_REFRESH_ACCESS_TOKEN" => "refresh-token" } }

    it "returns the environment token" do
      expect(described_class.call).to eq("env-token")
    end

    it "does not refresh the token" do
      described_class.call
      expect(WebMock).not_to have_requested(:post, token_url)
    end
  end

  context "when only EGI_REFRESH_ACCESS_TOKEN is set" do
    let(:env) { { "EGI_REFRESH_ACCESS_TOKEN" => "refresh-token" } }

    context "when the refresh succeeds" do
      before do
        stub_request(:post, token_url).with(
          body: {
            grant_type: "refresh_token",
            refresh_token: "refresh-token",
            client_id: "token-portal",
            scope: "openid email profile voperson_id eduperson_entitlement"
          },
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        ).to_return(
          status: 200,
          body: { access_token: "fresh-token" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "returns the refreshed token" do
        expect(described_class.call).to eq("fresh-token")
      end

      it "caches the refreshed token" do
        described_class.call
        expect(cache.read("egi_access_token")).to eq("fresh-token")
      end
    end

    context "when the refresh is rejected" do
      before do
        stub_request(:post, token_url).to_return(
          status: 400,
          body: { error: "invalid_grant" }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "raises an error" do
        expect { described_class.call }.to raise_error(Checkin::ServiceAccountToken::Error, /No EGI access token/)
      end
    end

    context "when the response has no access token" do
      before do
        stub_request(:post, token_url).to_return(
          status: 200,
          body: {}.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )
      end

      it "raises an error" do
        expect { described_class.call }.to raise_error(Checkin::ServiceAccountToken::Error)
      end
    end

    context "when the token endpoint is unreachable" do
      before { stub_request(:post, token_url).to_timeout }

      it "raises an error" do
        expect { described_class.call }.to raise_error(Checkin::ServiceAccountToken::Error)
      end
    end
  end

  context "when no token is available" do
    it "raises an error" do
      expect { described_class.call }.to raise_error(Checkin::ServiceAccountToken::Error, /No EGI access token/)
    end
  end
end
