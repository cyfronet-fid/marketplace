# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datasource::PcCreateOrUpdate, backend: true do
  let!(:provider) { create(:provider, pid: "provider-1") }
  let!(:scientific_domain) { create(:scientific_domain, eid: "scientific_domain-parent") }

  it "creates a datasource with an EOSC Registry source" do
    expect { described_class.new(payload, :published).call }.to change(Datasource, :count).by(1).and change(
            ServiceSource,
            :count
          ).by(1)

    datasource = Datasource.last
    expect(datasource.pid).to eq("datasource-1")
    expect(datasource.status).to eq("published")
    expect(datasource.upstream).to be_present
    expect(datasource.upstream.eid).to eq("datasource-1")
    expect(datasource.scientific_domains).to contain_exactly(scientific_domain)
  end

  it "updates existing datasource matched by legacy serviceId source" do
    datasource = create(:datasource, pid: "legacy-service-id", name: "Old name", resource_organisation: provider)
    source = create(:service_source, service: datasource, source_type: "eosc_registry", eid: "legacy-service-id")
    datasource.update!(upstream: source)

    expect { described_class.new(payload.merge("name" => "New name"), :published).call }.not_to change(
      Datasource,
      :count
    )

    datasource.reload
    expect(datasource.name).to eq("New name")
    expect(datasource.pid).to eq("datasource-1")
    expect(datasource.upstream.eid).to eq("datasource-1")
  end

  it "preserves incoming lifecycle statuses" do
    datasource = described_class.new(payload, :suspended).call

    expect(datasource.status).to eq("suspended")
  end

  def payload
    {
      "id" => "datasource-1",
      "serviceId" => "legacy-service-id",
      "name" => "Imported datasource",
      "description" => "Datasource description",
      "webpage" => "https://example.org/datasource",
      "resourceOrganisation" => provider.pid,
      "resourceProviders" => [provider.pid],
      "scientificDomains" => [{ "scientificDomain" => scientific_domain.eid }],
      "publicContacts" => ["ops@example.org"],
      "orderType" => "order_type-other",
      "versionControl" => true,
      "researchProductTypes" => ["dataset"]
    }
  end
end
