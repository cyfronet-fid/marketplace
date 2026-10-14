# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::FetchTemplate, type: :service do
  let(:raw_url) { "https://raw.githubusercontent.com/grycap/tosca/eosc_beyond/templates/jupyter.yml" }
  let(:dns) do
    {
      "raw.githubusercontent.com" => "185.199.108.133",
      "example.com" => "93.184.215.14",
      "internal.example" => "10.0.0.5",
      "169.254.169.254" => "169.254.169.254"
    }
  end

  # Unknown hosts raise KeyError, so no example can reach the real DNS
  before { allow(Addrinfo).to receive(:getaddrinfo) { |host, *| [Addrinfo.tcp(dns.fetch(host), 443)] } }

  it "fetches the raw template for a GitHub blob URL" do
    stub_request(:get, raw_url).to_return(status: 200, body: "tosca_definitions_version: tosca_simple_yaml_1_0")

    result = described_class.call("https://github.com/grycap/tosca/blob/eosc_beyond/templates/jupyter.yml")

    expect(result).to eq("tosca_definitions_version: tosca_simple_yaml_1_0")
  end

  it "fetches public http URLs as given" do
    stub_request(:get, "http://example.com/template.yml").to_return(status: 200, body: "template")

    expect(described_class.call("http://example.com/template.yml")).to eq("template")
  end

  it "raises an HTTP error when the template cannot be fetched" do
    stub_request(:get, raw_url).to_return(status: [404, "Not Found"])

    expect { described_class.call(raw_url) }.to raise_error(Faraday::ResourceNotFound)
  end

  it "follows a permanent redirect and returns only the final body" do
    stub_request(:get, raw_url).to_return(status: 301, body: "Moved", headers: { "Location" => "http://example.com/m" })
    stub_request(:get, "http://example.com/m").to_return(status: 200, body: "template")

    expect(described_class.call(raw_url)).to eq("template")
  end

  it "follows a temporary redirect with a relative location" do
    stub_request(:get, "https://example.com/a/t.yml").to_return(status: 302, headers: { "Location" => "../b.yml" })
    stub_request(:get, "https://example.com/b.yml").to_return(status: 200, body: "template")

    expect(described_class.call("https://example.com/a/t.yml")).to eq("template")
  end

  it "raises an HTTP error when the redirect limit is exceeded" do
    stub_request(:get, raw_url).to_return(status: 302, headers: { "Location" => raw_url })

    expect { described_class.call(raw_url) }.to raise_error(FaradayMiddleware::RedirectLimitReached)
  end

  it "raises an HTTP error for a redirect without a location" do
    stub_request(:get, raw_url).to_return(status: 302)

    expect { described_class.call(raw_url) }.to raise_error(FaradayMiddleware::RedirectLimitReached)
  end

  it "raises an error when the template is too large" do
    stub_request(:get, raw_url).to_return(status: 200, body: "a" * (described_class::MAX_SIZE + 1))

    expect { described_class.call(raw_url) }.to raise_error(Faraday::ResponseSizeLimit::Error)
  end

  describe "SSRF protection" do
    # No stub exists for blocked destinations, so reaching one would raise a WebMock error instead
    [
      "https://internal.example/t.yml",
      "http://169.254.169.254/latest/meta-data",
      "https://user:pass@example.com/t.yml",
      "ftp://example.com/t.yml"
    ].each do |url|
      it "rejects #{url} before making a request" do
        expect { described_class.call(url) }.to raise_error(Faraday::SsrfProtection::Error)
      end
    end

    it "rejects a malformed URL before making a request" do
      expect { described_class.call("https://exa mple.com/t.yml") }.to raise_error(URI::InvalidURIError)
    end

    it "blocks a redirect to the cloud metadata address" do
      stub_request(:get, raw_url).to_return(status: 302, headers: { "Location" => "http://169.254.169.254/latest/" })

      expect { described_class.call(raw_url) }.to raise_error(Faraday::SsrfProtection::Error)
    end

    it "blocks a redirect to a non-http(s) location" do
      stub_request(:get, raw_url).to_return(status: 301, headers: { "Location" => "file:///etc/passwd" })

      expect { described_class.call(raw_url) }.to raise_error(Faraday::SsrfProtection::Error, "URL is not allowed")
    end

    context "with a multi-hop redirect chain ending at an internal host" do
      before do
        stub_request(:get, raw_url).to_return(status: 302, headers: { "Location" => "https://example.com/hop" })
        stub_request(:get, "https://example.com/hop").to_return(
          status: 302,
          headers: { "Location" => "https://internal.example/" }
        )
      end

      it "blocks the internal hop" do
        expect { described_class.call(raw_url) }.to raise_error(
          Faraday::SsrfProtection::Error,
          "URL host is not allowed"
        )
      end
    end

    context "with a proxy configured in the environment" do
      around do |example|
        original = ENV.values_at("http_proxy", "https_proxy")
        ENV["http_proxy"] = ENV["https_proxy"] = "http://proxy.internal:3128"
        example.run
      ensure
        ENV["http_proxy"], ENV["https_proxy"] = original
      end

      before do
        stub_request(:get, raw_url).to_return(status: 200, body: "template")
        allow(Net::HTTP).to receive(:new).and_call_original
      end

      it "connects directly so the pinned address is used" do
        described_class.call(raw_url)

        expect(Net::HTTP).to have_received(:new).with("raw.githubusercontent.com", 443, nil)
      end
    end
  end
end
