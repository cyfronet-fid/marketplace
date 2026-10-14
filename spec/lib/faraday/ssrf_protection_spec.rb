# frozen_string_literal: true

require "rails_helper"

RSpec.describe Faraday::SsrfProtection do
  let(:middleware) { described_class.new(->(env) { env }) }
  let(:url) { "https://templates.example/t.yml" }
  let(:env) { Faraday::Env.from(url: URI.parse(url), request: Faraday::RequestOptions.new) }

  describe "#on_request" do
    %w[93.184.215.14 2606:2800:21f:cb07:6820:80da:af6b:8b2c].each do |address|
      context "when the host resolves to public #{address}" do
        before { allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.tcp(address, 443)]) }

        it "passes the checked address to the adapter" do
          middleware.on_request(env)

          expect(env.request.context).to eq(ssrf_target: { host: "templates.example", address: address })
        end
      end
    end

    %w[
      127.0.0.1
      10.1.2.3
      172.16.0.1
      192.168.1.1
      169.254.169.254
      0.0.0.0
      100.100.100.200
      224.0.0.1
      ::1
      ::
      fd00:ec2::254
      fe80::1
      ff02::1
      ::ffff:127.0.0.1
      ::ffff:169.254.169.254
      64:ff9b::a00:1
    ].each do |address|
      context "when the host resolves to #{address}" do
        before { allow(Addrinfo).to receive(:getaddrinfo).and_return([Addrinfo.tcp(address, 443)]) }

        it "rejects it without exposing the address" do
          expect { middleware.on_request(env) }.to raise_error(described_class::Error, "URL host is not allowed")
        end
      end
    end

    context "when one of several resolved addresses is internal" do
      before do
        allow(Addrinfo).to receive(:getaddrinfo).and_return(
          [Addrinfo.tcp("93.184.215.14", 443), Addrinfo.tcp("10.0.0.5", 443)]
        )
      end

      it "rejects the host" do
        expect { middleware.on_request(env) }.to raise_error(described_class::Error)
      end
    end

    context "when the host cannot be resolved" do
      before { allow(Addrinfo).to receive(:getaddrinfo).and_raise(SocketError, "Name or service not known") }

      it "raises a protection error" do
        expect { middleware.on_request(env) }.to raise_error(described_class::Error, "URL host could not be resolved")
      end
    end

    [
      "ftp://example.com/t.yml",
      "file:///etc/passwd",
      "javascript:alert(1)",
      "https:///t.yml",
      "//example.com/t.yml",
      "https://user:pass@example.com/t.yml"
    ].each do |rejected_url|
      context "with #{rejected_url}" do
        let(:url) { rejected_url }

        it "rejects the URL" do
          expect { middleware.on_request(env) }.to raise_error(described_class::Error, "URL is not allowed")
        end
      end
    end

    # Numeric host forms are parsed locally by getaddrinfo (no DNS query) and normalized to 127.0.0.1
    %w[2130706433 0x7f000001 127.1].each do |host|
      context "with the alternative loopback form #{host}" do
        let(:url) { "http://#{host}/t.yml" }

        it "rejects the host" do
          expect { middleware.on_request(env) }.to raise_error(described_class::Error, "URL host is not allowed")
        end
      end
    end

    context "with a proxy" do
      before { env.request.proxy = Faraday::ProxyOptions.from("http://proxy.example:3128") }

      it "rejects the request" do
        expect { middleware.on_request(env) }.to raise_error(described_class::Error, "Proxied requests are not allowed")
      end
    end
  end

  describe Faraday::SsrfProtection::NetHttp do
    let(:adapter) { described_class.new(->(env) { env }) }

    it "connects to the address checked by the middleware" do
      env.request.context = { ssrf_target: { host: "templates.example", address: "93.184.215.14" } }

      expect(adapter.net_http_connection(env).ipaddr).to eq("93.184.215.14")
    end

    it "refuses requests that were not checked by the middleware" do
      expect { adapter.net_http_connection(env) }.to raise_error(
        Faraday::SsrfProtection::Error,
        "Request was not checked by SsrfProtection"
      )
    end

    it "refuses an address checked for a different host" do
      env.request.context = { ssrf_target: { host: "other.example", address: "93.184.215.14" } }

      expect { adapter.net_http_connection(env) }.to raise_error(Faraday::SsrfProtection::Error)
    end
  end
end
