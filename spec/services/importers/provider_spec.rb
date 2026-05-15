# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Provider, backend: true do
  let(:legal_status) { create(:legal_status, eid: "provider_legal_status-public_legal_entity") }
  let(:hosting_legal_entity) do
    Vocabulary::HostingLegalEntity.create!(
      eid: "provider_hosting_legal_entity-cyfronet",
      name: "Cyfronet",
      description: "Cyfronet",
      extras: {
      }
    )
  end
  let(:node) { create(:node, eid: "node-egi") }

  it "returns provider hash from a V6 organisation payload" do
    current_time = 1_613_193_818_577
    payload = {
      "id" => "21.11170/cI5H3q",
      "name" => "Cyfronet",
      "abbreviation" => "CYF",
      "website" => "https://www.cyfronet.pl",
      "country" => "PL",
      "legalEntity" => true,
      "legalStatus" => "provider_legal_status-public_legal_entity",
      "hostingLegalEntity" => "provider_hosting_legal_entity-cyfronet",
      "description" => "Test provider for V6 organisation endpoint",
      "nodePID" => "node-egi",
      "publicContacts" => ["info@example.org", { "email" => "help@example.org" }, "info@example.org"],
      "alternativePIDs" => [{ "pid" => "eosc.cyfronet", "pidSchema" => "EOSC PID" }],
      "mainContact" => {
        "email" => "ignored@example.org"
      },
      "users" => [{ "email" => "ignored-admin@example.org" }]
    }
    provider_mapper = described_class.new(payload, current_time)

    imported_hash = provider_mapper.call

    expect(imported_hash).to include(
      pid: "21.11170/cI5H3q",
      name: "Cyfronet",
      abbreviation: "CYF",
      website: "https://www.cyfronet.pl",
      country: "PL",
      legal_entity: true,
      description: "Test provider for V6 organisation endpoint",
      public_contact_emails: %w[info@example.org help@example.org],
      ppid: "eosc.cyfronet",
      synchronized_at: current_time,
      status: :published
    )
    expect(imported_hash[:legal_statuses]).to contain_exactly(legal_status)
    expect(imported_hash[:hosting_legal_entities]).to contain_exactly(hosting_legal_entity)
    expect(imported_hash[:nodes]).to contain_exactly(node)
    expect(imported_hash[:alternative_identifiers].map(&:value)).to contain_exactly("eosc.cyfronet")
    expect(imported_hash).not_to include(:main_contact, :public_contacts, :data_administrators)
  end

  it "handles missing optional V6 fields" do
    imported_hash = described_class.call({ "id" => "provider-1", "publicContacts" => nil }, 123)

    expect(imported_hash[:public_contact_emails]).to eq([])
    expect(imported_hash[:alternative_identifiers]).to eq([])
    expect(imported_hash[:ppid]).to eq("")
  end
end
