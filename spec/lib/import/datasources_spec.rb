# frozen_string_literal: true

require "rails_helper"
require "ostruct"

describe Import::Datasources, backend: true do
  let(:test_url) { "https://localhost/api" }
  let(:faraday) { Faraday }
  let(:logger) { ->(_msg) {} }
  let(:token) { "test_token" }
  let(:response) { double(status: 200, body: { "results" => [datasource_data] }) }
  let(:datasource_data) do
    {
      "id" => "bluebridge.invalid-datasource",
      "type" => "DataSource",
      "name" => "Invalid datasource",
      "description" => "Datasource saved as draft after validation failure",
      "webpage" => "not-a-url",
      "resourceOwner" => "bluebridge",
      "resourceProviders" => ["bluebridge"],
      "orderType" => "order_type-other",
      "publicContacts" => [{ "email" => "contact@example.org" }],
      "versionControl" => false
    }
  end

  before do
    create(:provider, pid: "bluebridge")

    allow(Importers::Token).to receive(:new).with(faraday: faraday).and_return(double(receive_token: token))
    allow(Importers::Request).to receive(:new).with(
      test_url,
      "public/datasource",
      faraday: faraday,
      token: token
    ).and_return(double(call: response))
    allow(Datasource).to receive(:reindex)
  end

  it "sets EOSC Registry as upstream when a new invalid datasource is saved as draft" do
    importer = described_class.new(test_url, dry_run: false, faraday: faraday, logger: logger)

    expect { importer.call }.to change(Datasource, :count).by(1).and change(ServiceSource, :count).by(1)

    datasource = Datasource.last
    source = ServiceSource.last

    expect(datasource.status).to eq("draft")
    expect(source).to have_attributes(
      service_id: datasource.id,
      eid: "bluebridge.invalid-datasource",
      source_type: "eosc_registry"
    )
    expect(datasource.upstream_id).to eq(source.id)
  end
end
