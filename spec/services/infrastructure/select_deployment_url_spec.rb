# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::SelectDeploymentUrl do
  it "returns the URL output whatever its name" do
    outputs = { "jupyter_url" => "https://notebook.vm.fedcloud.eu/?token=secret" }

    expect(described_class.call(outputs)).to eq("https://notebook.vm.fedcloud.eu/?token=secret")
  end

  it "returns nil without outputs" do
    expect(described_class.call(nil)).to be_nil
  end

  it "returns the first URL output in declaration order" do
    outputs = { "notebook_url" => "https://notebook.vm.fedcloud.eu/", "admin_url" => "https://admin.example.com/" }

    expect(described_class.call(outputs, %w[admin_url notebook_url])).to eq("https://admin.example.com/")
  end

  it "prefers a DNS URL over an IP address URL declared before it" do
    outputs = { "jupyter_url_ip" => "https://10.0.0.1/", "jupyter_dns_url" => "https://notebook.vm.fedcloud.eu/" }

    expect(described_class.call(outputs, %w[jupyter_url_ip jupyter_dns_url])).to eq("https://notebook.vm.fedcloud.eu/")
  end

  it "falls back to an IP address URL when there is no DNS URL" do
    outputs = { "jupyter_url_ip" => "https://10.0.0.1/", "ipv6_url" => "https://[2001:db8::1]/" }

    expect(described_class.call(outputs, %w[jupyter_url_ip ipv6_url])).to eq("https://10.0.0.1/")
  end

  describe ".dns_url?" do
    it "is true for a URL with a DNS host" do
      expect(described_class.dns_url?("https://notebook.vm.fedcloud.eu/")).to be(true)
    end

    it "is false for an IP address URL" do
      expect(described_class.dns_url?("https://10.0.0.1/")).to be(false)
    end

    it "is false without a URL" do
      expect(described_class.dns_url?(nil)).to be(false)
    end
  end

  it "skips outputs that are not http(s) URLs with a host" do
    outputs = { "ip" => "10.0.0.1", "ssh" => "ssh://10.0.0.1", "unresolved" => "https:///", "bad" => "https://a b" }

    expect(described_class.call(outputs.merge("url" => "https://public.example.com"))).to eq(
      "https://public.example.com"
    )
  end
end
