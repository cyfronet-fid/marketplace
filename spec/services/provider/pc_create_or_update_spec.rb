# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::PcCreateOrUpdate, backend: true do
  let(:published_provider_response) { create(:jms_published_provider_response) }
  let(:draft_provider_response) { create(:jms_draft_provider_response) }
  let(:modified_at) { Time.zone.local(2026, 5, 20, 12, 0, 0) }
  let(:logger) { Logger.new($stdout) }

  before(:each) { allow_any_instance_of(Importers::Logo).to receive(:call) }

  it "should create provider with source and upstream is true" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect { described_class.new(published_provider_response, :published, Time.now).call }.to change {
      Provider.count
    }.by(1)

    provider = Provider.last

    expect(provider.name).to eq("Test Provider tp")
    expect(provider.sources.length).to eq(1)
    expect(provider.sources[0].eid).to eq("tp")
    expect(provider.upstream_id).to eq(provider.sources[0].id)
    expect(provider.published?).to be_truthy
    $stdout = original_stdout
  end

  it "should update provider when it is active" do
    original_stdout = $stdout
    $stdout = StringIO.new
    provider =
      create(
        :provider,
        name: "new provider",
        sources: [build(:provider_source, provider: provider, source_type: "eosc_registry", eid: "new.provider")]
      )

    expect do
      described_class.new(
        create(:jms_published_provider_response, eid: "new.provider", name: "Supper new name for updated provider"),
        :published,
        Time.now.to_i
      ).call
    end.to change { Provider.count }.by(0)

    updated_provider = Provider.find(provider.id)

    expect(updated_provider.name).to eq("Supper new name for updated provider")
    expect(updated_provider.sources.length).to eq(1)
    expect(updated_provider.sources[0].eid).to eq("new.provider")
    expect(updated_provider.upstream_id).to eq(updated_provider.sources[0].id)
    expect(updated_provider.published?).to be_truthy
    $stdout = original_stdout
  end

  it "should update provider when it isn't active" do
    original_stdout = $stdout
    $stdout = StringIO.new
    provider =
      create(
        :provider,
        name: "new provider",
        sources: [build(:provider_source, provider: provider, source_type: "eosc_registry", eid: "new.provider")]
      )

    expect do
      described_class.new(
        create(:jms_draft_provider_response, eid: "new.provider", name: "Supper new name for updated  provider"),
        :unpublished,
        Time.now.to_i
      ).call
    end.to change { Provider.count }.by(0)

    updated_provider = Provider.find(provider.id)

    expect(updated_provider.name).to eq("Supper new name for updated  provider")
    expect(updated_provider.sources.length).to eq(1)
    expect(updated_provider.sources[0].eid).to eq("new.provider")
    expect(updated_provider.upstream_id).to eq(updated_provider.sources[0].id)
    expect(updated_provider.unpublished?).to be_truthy
    $stdout = original_stdout
  end

  it "should create provider with source and upstream and it isn't active" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect { described_class.new(draft_provider_response, :unpublished, Time.now).call }.to change {
      Provider.count
    }.by(1)

    provider = Provider.last

    expect(provider.name).to eq("Test Provider tp")
    expect(provider.sources.length).to eq(1)
    expect(provider.sources[0].eid).to eq("tp")
    expect(provider.upstream_id).to eq(provider.sources[0].id)
    expect(provider.unpublished?).to be_truthy
    $stdout = original_stdout
  end

  it "updates existing provider matched by EOSC Registry source" do
    provider = create(:provider, pid: "provider-1", name: "Old name")
    provider.sources.first.update!(source_type: "eosc_registry", eid: "provider-1")

    expect { described_class.call(payload("provider-1", name: "New name"), :published, modified_at) }.not_to change(
      Provider,
      :count
    )

    expect(provider.reload.name).to eq("New name")
  end

  it "reuses existing provider matched by EOSC PID alternative identifier" do
    provider = create(:provider, pid: "legacy-pid")
    provider.alternative_identifiers << AlternativeIdentifier.create!(
      identifier_type: "EOSC PID",
      value: "eosc.provider"
    )

    expect { described_class.call(payload("provider-1"), :published, modified_at) }.not_to change(Provider, :count)

    provider.reload
    expect(provider.pid).to eq("provider-1")
    expect(provider.sources.find_by(source_type: "eosc_registry", eid: "provider-1")).to be_present
    expect(provider.upstream).to eq(provider.sources.find_by(source_type: "eosc_registry", eid: "provider-1"))
  end

  def payload(id, name: "Provider from PC")
    {
      "id" => id,
      "name" => name,
      "abbreviation" => "PCP",
      "website" => "https://example.org",
      "country" => "PL",
      "legalEntity" => true,
      "description" => "Imported provider",
      "publicContacts" => ["ops@example.org"],
      "alternativePIDs" => [{ "pid" => "eosc.provider", "pidSchema" => "EOSC PID" }]
    }
  end
end
