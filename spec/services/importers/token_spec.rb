# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Token, :backend do
  subject(:token) { described_class.new(faraday: faraday) }

  let(:faraday) { class_double(Faraday) }
  let(:response) { instance_double(Faraday::Response, blank?: false, body: '{"access_token":"abc123"}') }

  context "with a refresh token" do
    before do
      stub_const("Importers::Token::REFRESH_TOKEN", "refresh-token-value")
      stub_const("Importers::Token::CLIENT_ID", "client-id-value")
      allow(faraday).to receive(:post).and_return(response)
    end

    it "requests a token using the refresh_token grant" do
      token.receive_token

      expect(faraday).to have_received(:post).with(
        anything,
        { grant_type: "refresh_token", refresh_token: "refresh-token-value", client_id: "client-id-value" }
      )
    end

    it "returns the access token" do
      expect(token.receive_token).to eq("abc123")
    end
  end

  context "when the response has no access token" do
    before do
      allow(faraday).to receive(:post).and_return(instance_double(Faraday::Response, blank?: true))
    end

    it "raises Importers::Token::RequestError" do
      expect { token.receive_token }.to raise_error(Importers::Token::RequestError)
    end
  end
end
