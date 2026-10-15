# frozen_string_literal: true

require "rails_helper"

RSpec.describe HttpMiddleware::ResponseSizeLimit do
  let(:url) { "https://example.com/template.yml" }
  let(:connection) do
    Faraday.new do |f|
      f.response :raise_error
      f.response :follow_redirects
      f.use described_class, max: 10
      f.adapter :net_http
    end
  end

  it "returns a body within the limit" do
    stub_request(:get, url).to_return(body: "a" * 10)

    expect(connection.get(url).body).to eq("a" * 10)
  end

  it "returns an empty body" do
    stub_request(:get, url).to_return(status: 204)

    expect(connection.get(url).body).to eq("")
  end

  it "raises once the streamed body exceeds the limit" do
    stub_request(:get, url).to_return(body: "a" * 11)

    expect { connection.get(url) }.to raise_error(described_class::Error, "Response is larger than 10 bytes")
  end

  it "keeps only the final response body after a redirect" do
    stub_request(:get, url).to_return(status: 301, body: "Moved", headers: { "Location" => "https://example.com/new" })
    stub_request(:get, "https://example.com/new").to_return(body: "template")

    expect(connection.get(url).body).to eq("template")
  end

  it "keeps the body of error responses" do
    stub_request(:get, url).to_return(status: 404, body: "missing")

    expect { connection.get(url) }.to raise_error(having_attributes(response: include(body: "missing")))
  end
end
