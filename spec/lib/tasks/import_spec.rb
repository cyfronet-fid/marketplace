# frozen_string_literal: true

require "rails_helper"

describe "import:resources", type: :task, backend: true do
  let(:resource_importer) { double("Import::Resources") }
  let(:provider_importer) { double("Import::Providers") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with(
      "MP_IMPORT_EOSC_REGISTRY_URL",
      "https://integration.providers.sandbox.eosc-beyond.eu/api"
    ).and_return("https://integration.providers.sandbox.eosc-beyond.eu/api")
    allow(ENV).to receive(:fetch).with("DRY_RUN", false).and_return(false)
    allow(ENV).to receive(:fetch).with("IDS", "").and_return("")
    allow(ENV).to receive(:fetch).with("OUTPUT", nil).and_return(nil)
    allow(ENV).to receive(:fetch).with("UPSTREAM", "eosc_registry").and_return("eosc_registry")
    allow(ENV).to receive(:fetch).with("MP_IMPORT_TOKEN", nil).and_return(nil)
    allow(ENV).to receive(:fetch).with("MP_IMPORT_RESCUE_MODE", false).and_return(false)
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should pass ENV variables" do
    allow(resource_importer).to receive(:call)
    import_class_stub = class_double(Import::Resources).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://integration.providers.sandbox.eosc-beyond.eu/api",
      dry_run: false,
      ids: [],
      filepath: nil,
      default_upstream: :eosc_registry,
      token: nil,
      rescue_mode: false
    ).and_return(resource_importer)

    subject.invoke
  end

  it "should call Import::Resources.call" do
    allow(resource_importer).to receive(:call)
    import_class_stub = class_double(Import::Resources).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://integration.providers.sandbox.eosc-beyond.eu/api",
      default_upstream: :eosc_registry,
      dry_run: false,
      filepath: nil,
      ids: [],
      token: nil,
      rescue_mode: false
    ).and_return(resource_importer)

    subject.invoke
  end

  it "should call Import::Providers.call" do
    allow(provider_importer).to receive(:call)
    import_class_stub = class_double(Import::Providers).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with(
      "https://integration.providers.sandbox.eosc-beyond.eu/api",
      dry_run: false,
      filepath: nil
    ).and_return(provider_importer)

    subject.invoke
  end
end
