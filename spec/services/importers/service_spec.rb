# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Service, backend: true do
  let!(:provider) { create(:provider, pid: "provider-1") }
  let!(:scientific_domain) { create(:scientific_domain, eid: "scientific_domain-parent") }
  let(:synchronized_at) { Time.zone.local(2026, 5, 20, 12, 0, 0) }

  it "maps parent scientific domain from an array when V6 payload omits subdomain" do
    result = described_class.call(payload, synchronized_at, "https://example.test/api")

    expect(result[:scientific_domains]).to contain_exactly(scientific_domain)
  end

  it "maps parent scientific domain from an object when V6 payload omits subdomain" do
    payload["scientificDomains"] = payload.fetch("scientificDomains").first

    result = described_class.call(payload, synchronized_at, "https://example.test/api")

    expect(result[:scientific_domains]).to contain_exactly(scientific_domain)
  end

  def payload
    {
      "id" => "service-1",
      "name" => "Parent-domain service",
      "description" => "Imported from PC",
      "webpage" => "https://example.org/service",
      "resourceOrganisation" => provider.pid,
      "resourceProviders" => [provider.pid],
      "scientificDomains" => [{ "scientificDomain" => scientific_domain.eid, "scientificSubdomain" => nil }],
      "categories" => [],
      "publicContacts" => ["ops@example.org"],
      "orderType" => "order_type-other"
    }
  end
end
