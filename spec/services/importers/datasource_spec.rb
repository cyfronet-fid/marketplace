# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Datasource, :backend do
  let!(:classification) do
    Vocabulary::DatasourceClassification.create!(
      eid: "ds_classification-aggregators",
      name: "Aggregators",
      description: "Aggregators"
    )
  end

  it "returns V6 datasource-specific attributes" do
    payload = {
      "type" => "DataSource",
      "versionControl" => true,
      "datasourceClassification" => "ds_classification-aggregators",
      "researchProductTypes" => %w[ds_research_entity_type-research_data dataset],
      "thematic" => true,
      "accessTypes" => "access_type-remote"
    }

    imported_hash = described_class.call(payload)

    expect(imported_hash).to include(
      version_control: true,
      datasource_classification: classification,
      research_product_types: %w[ds_research_entity_type-research_data dataset],
      thematic: true,
      order_type: "other"
    )
  end

  it "ignores removed V5 datasource structures" do
    payload = {
      "versionControl" => nil,
      "persistentIdentitySystems" => ["entityType" => "removed"],
      "researchEntityTypes" => ["removed"],
      "researchProductLicensings" => ["removed"],
      "researchProductMetadataLicensing" => ["removed"],
      "researchProductAccessPolicies" => ["removed"],
      "researchProductMetadataAccessPolicies" => ["removed"],
      "submissionPolicyURL" => "https://example.org/submission",
      "preservationPolicyURL" => "https://example.org/preservation",
      "harvestable" => true,
      "researchProductTypes" => nil
    }

    imported_hash = described_class.call(payload)

    expect(imported_hash).to include(
      version_control: false,
      datasource_classification: nil,
      research_product_types: [],
      thematic: false
    )
  end

  context "when running as pl" do
    subject(:result) { described_class.call(v5_payload) }

    let(:v5_payload) do
      {
        "submissionPolicyURL" => "https://example.org/submission",
        "preservationPolicyURL" => "https://example.org/preservation",
        "harvestable" => true,
        "researchProductLicensings" => {
          "researchProductLicenseName" => "CC BY",
          "researchProductLicenseURL" => "https://example.org/cc-by"
        }
      }
    end

    before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

    it "maps the V5 datasource policies" do
      expect(result).to include(
        submission_policy_url: "https://example.org/submission",
        preservation_policy_url: "https://example.org/preservation",
        harvestable: true
      )
    end

    it "builds the research product license links" do
      expect(result[:link_research_product_license_urls]).to contain_exactly(
        have_attributes(name: "CC BY", url: "https://example.org/cc-by")
      )
    end
  end

  it "maps common V6 service fields for standalone datasource creation" do
    provider = create(:provider, pid: "provider-1")
    scientific_domain = create(:scientific_domain, eid: "scientific_domain-parent")

    imported_hash =
      described_class.call(
        {
          "id" => "datasource-1",
          "name" => "Standalone datasource",
          "description" => "Datasource description",
          "resourceOrganisation" => provider.pid,
          "resourceProviders" => [provider.pid],
          "scientificDomains" => ["scientificDomain" => scientific_domain.eid],
          "publicContacts" => ["ops@example.org"],
          "orderType" => "order_type-other"
        }
      )

    expect(imported_hash).to include(
      pid: "datasource-1",
      name: "Standalone datasource",
      resource_organisation: provider,
      providers: [provider],
      scientific_domains: contain_exactly(scientific_domain),
      public_contact_emails: ["ops@example.org"],
      order_type: "other"
    )
  end
end
