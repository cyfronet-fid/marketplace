# frozen_string_literal: true

require "rails_helper"

describe "import:resources", type: :task do
  let(:resource_importer) { double("Import::Resources") }
  let(:provider_importer) { double("Import::Providers") }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should pass ENV variables" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).with(
      "MP_IMPORT_EOSC_REGISTRY_URL",
      "https://beta.providers.eosc-portal.eu/api"
    ).and_return("https://api.custom")
    allow(ENV).to receive(:fetch).with("DRY_RUN", false).and_return(true)
    allow(ENV).to receive(:fetch).with("IDS", "").and_return("sampleeid,sampleeid2")
    allow(ENV).to receive(:fetch).with("OUTPUT", nil).and_return("/tmp/output.json")
    allow(ENV).to receive(:fetch).with("UPSTREAM", "eosc_registry").and_return("eosc_registry")
    allow(ENV).to receive(:fetch).with("MP_IMPORT_TOKEN", nil).and_return("password")

    allow(resource_importer).to receive(:call)
    import_class_stub = class_double(Import::Resources).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://api.custom",
      dry_run: true,
      ids: %w[sampleeid sampleeid2],
      filepath: "/tmp/output.json",
      default_upstream: :eosc_registry,
      token: "password"
    ).and_return(resource_importer)

    subject.invoke
  end

  it "should call Import::Resources.call" do
    allow(resource_importer).to receive(:call)
    import_class_stub = class_double(Import::Resources).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://beta.providers.eosc-portal.eu/api",
      default_upstream: :mp,
      dry_run: false,
      filepath: nil,
      ids: [],
      token: nil
    ).and_return(resource_importer)

    subject.invoke
  end

  it "should call Import::Providers.call" do
    allow(provider_importer).to receive(:call)
    import_class_stub = class_double(Import::Providers).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://beta.providers.eosc-portal.eu/api",
      dry_run: false,
      filepath: nil
    ).and_return(provider_importer)

    subject.invoke
  end
end
