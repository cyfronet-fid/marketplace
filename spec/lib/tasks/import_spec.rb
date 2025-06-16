# frozen_string_literal: true

require "rails_helper"

describe "import:resources", type: :task, backend: true do
  let(:resource_importer) { double("Import::Resources") }
  let(:provider_importer) { double("Import::Providers") }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should pass ENV variables" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MP_IMPORT_EOSC_REGISTRY_URL").and_return(
      "https://integration.providers.sandbox.eosc-beyond.eu/api"
    )
    allow(ENV).to receive(:[]).with("DRY_RUN").and_return("1")
    allow(ENV).to receive(:[]).with("IDS").and_return("sampleeid,sampleeid2")
    allow(ENV).to receive(:[]).with("OUTPUT").and_return("/tmp/output.json")
    allow(ENV).to receive(:[]).with("UPSTREAM").and_return("eosc_registry")
    allow(ENV).to receive(:[]).with("MP_IMPORT_TOKEN").and_return("password")

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
