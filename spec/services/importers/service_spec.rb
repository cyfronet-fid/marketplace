# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Service, :backend do
  let!(:provider) { create(:provider, pid: "provider-1") }
  let!(:scientific_domain) { create(:scientific_domain, eid: "scientific_domain-parent") }
  let(:synchronized_at) { Time.zone.local(2026, 5, 20, 12, 0, 0) }

  it "maps parent scientific domain from an array when V6 payload omits subdomain" do
    result = described_class.call(payload, synchronized_at)

    expect(result[:scientific_domains]).to contain_exactly(scientific_domain)
  end

  it "maps parent scientific domain from an object when V6 payload omits subdomain" do
    payload["scientificDomains"] = payload.fetch("scientificDomains").first

    result = described_class.call(payload, synchronized_at)

    expect(result[:scientific_domains]).to contain_exactly(scientific_domain)
  end

  context "when running as pl" do
    subject(:result) { described_class.call(v5_payload, synchronized_at) }

    let(:v5_payload) { JSON.parse(create(:jms_json_service))["resource"]["service"] }
    let!(:service_category) do
      Vocabulary::ServiceCategory.create!(
        eid: "service-category-compute",
        name: "Compute",
        description: "Compute",
        extras: {}
      )
    end

    before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

    it "maps the V5 profile fields" do
      expect(result).to include(
        tagline: "Find easily accessible corpora of scholarly content and mine them!",
        horizontal: true,
        helpdesk_url: "https://services.openminted.eu/support",
        version: "1.0"
      )
    end

    it "maps the V5 vocabularies" do
      expect(result[:service_categories]).to contain_exactly(service_category)
    end
  end

  def payload
    {
      "id" => "service-1",
      "name" => "Parent-domain service",
      "description" => "Imported from PC",
      "webpage" => "https://example.org/service",
      "resourceOrganisation" => provider.pid,
      "resourceProviders" => [provider.pid],
      "scientificDomains" => ["scientificDomain" => scientific_domain.eid, "scientificSubdomain" => nil],
      "categories" => [],
      "publicContacts" => ["ops@example.org"],
      "orderType" => "order_type-other"
    }
  end
end
