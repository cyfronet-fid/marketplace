# frozen_string_literal: true

require "rails_helper"

describe Import::Guidelines, backend: true do
  let(:test_url) { "https://localhost/api" }
  let(:faraday) { Faraday }
  let(:logger) { ->(_msg) {} }

  def stub_responses(guideline_records, connection_records = [])
    guidelines_response = double(status: 200, body: { "results" => guideline_records })
    connections_response = double(status: 200, body: { "results" => connection_records })

    allow(Importers::Request).to receive(:new).with(
      test_url,
      "public/interoperabilityRecord",
      faraday: faraday,
      token: nil
    ).and_return(double(call: guidelines_response))
    allow(Importers::Request).to receive(:new).with(
      test_url,
      "public/resourceInteroperabilityRecord",
      faraday: faraday,
      token: nil
    ).and_return(double(call: connections_response))
  end

  it "persists guideline title from V6 name" do
    guideline_records = [{ "id" => "guideline-v6", "name" => "V6 interoperability guideline" }]
    stub_responses(guideline_records)
    importer = described_class.new(test_url, dry_run: false, faraday: faraday, logger: logger)

    expect { importer.call }.to change(Guideline, :count).by(1)
    expect(Guideline.last).to have_attributes(eid: "guideline-v6", title: "V6 interoperability guideline")
  end

  it "falls back to legacy title" do
    guideline_records = [{ "id" => "guideline-v5", "title" => "Legacy guideline title" }]
    stub_responses(guideline_records)
    importer = described_class.new(test_url, dry_run: false, faraday: faraday, logger: logger)

    expect { importer.call }.to change(Guideline, :count).by(1)
    expect(Guideline.last).to have_attributes(eid: "guideline-v5", title: "Legacy guideline title")
  end

  it "connects existing services to existing guidelines" do
    guideline_records = []
    service = create(:service)
    guideline = Guideline.create!(eid: "guideline-v6", title: "V6 interoperability guideline")
    create(:service_source, eid: "service-v6", source_type: "eosc_registry", service: service)
    connection_records = [{ "resourceId" => "service-v6", "interoperabilityRecordIds" => ["guideline-v6"] }]
    stub_responses(guideline_records, connection_records)
    importer = described_class.new(test_url, dry_run: false, faraday: faraday, logger: logger)

    expect { importer.call }.to change(ServiceGuideline, :count).by(1)
    expect(service.reload.guidelines).to contain_exactly(guideline)
  end
end
