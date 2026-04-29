# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::DeployableService, backend: true do
  let(:provider_pid) { "21.T15999/dAyH3s" }
  let!(:provider) { create(:provider, pid: provider_pid) }
  let!(:scientific_subdomain) { create(:scientific_domain, eid: "scientific_subdomain-compute") }
  let(:synchronized_at) { Time.zone.local(2026, 4, 29, 12, 0, 0) }

  describe "#call" do
    it "maps a V6 Deployable Application payload" do
      result = described_class.call(v6_payload, synchronized_at, "https://example.test/api")

      expect(result).to include(
        pid: "21.T15999/DA-example",
        name: "Example DA",
        abbreviation: "EXDA",
        description: "An example deployable application",
        tagline: "Example tagline",
        logo_url: "https://example.org/logo.png",
        resource_organisation: provider,
        node: "node-eosc",
        urls: ["https://example.org/app"],
        url: "https://example.org/app",
        public_contact_emails: ["ops@example.org"],
        publishing_date: "2026-04-15",
        resource_type: "DeployableApplication",
        version: "1.2.0",
        last_update: "2026-04-14",
        license_name: "Apache-2.0",
        license_url: "https://www.apache.org/licenses/LICENSE-2.0",
        creators: [{ "name" => "Alice", "email" => "alice@example.org" }],
        tag_list: ["alpha"],
        synchronized_at: synchronized_at,
        status: :published
      )
      expect(result[:scientific_domains]).to contain_exactly(scientific_subdomain)
    end

    it "tolerates omitted optional V6 fields" do
      result =
        described_class.call(
          v6_payload.except("urls", "alternativePIDs", "license", "description", "tagline").merge(
            "publicContacts" => [],
            "nodePID" => nil
          ),
          synchronized_at,
          "https://example.test/api"
        )

      expect(result[:description]).to be_nil
      expect(result[:tagline]).to be_nil
      expect(result[:urls]).to eq([])
      expect(result[:url]).to be_nil
      expect(result[:node]).to be_nil
      expect(result[:public_contact_emails]).to eq([])
      expect(result[:license_name]).to be_nil
      expect(result[:license_url]).to be_nil
    end
  end

  def v6_payload
    {
      "id" => "21.T15999/DA-example",
      "name" => "Example DA",
      "description" => "An example deployable application",
      "tagline" => "Example tagline",
      "acronym" => "EXDA",
      "logo" => "https://example.org/logo.png",
      "publishingDate" => "2026-04-15",
      "type" => "DeployableApplication",
      "resourceOwner" => provider_pid,
      "nodePID" => "node-eosc",
      "publicContacts" => ["ops@example.org"],
      "urls" => ["https://example.org/app"],
      "version" => "1.2.0",
      "lastUpdate" => "2026-04-14",
      "license" => {
        "name" => "Apache-2.0",
        "url" => "https://www.apache.org/licenses/LICENSE-2.0"
      },
      "scientificDomains" => [
        {
          "scientificDomain" => "scientific_domain-natural-sciences",
          "scientificSubdomain" => scientific_subdomain.eid
        }
      ],
      "tags" => ["alpha"],
      "creators" => [{ "name" => "Alice", "email" => "alice@example.org" }]
    }
  end
end
