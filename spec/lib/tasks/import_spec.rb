# frozen_string_literal: true

require "rails_helper"

describe "import:eic", type: :task do
  let(:importer) { double("Import::EIC") }

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should pass ENV variables" do
    allow(ENV).to receive(:[]).with("MP_IMPORT_EIC_URL").and_return("https://api.custom")
    allow(ENV).to receive(:[]).with("DRY_RUN").and_return("1")
    allow(ENV).to receive(:[]).with("DONT_CREATE_PROVIDERS").and_return("1")

    allow(importer).to receive(:call)
    import_class_stub = class_double(Import::EIC).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).to receive(:new).with("https://api.custom", "1", "1")
                                    .and_return(importer)

    subject.invoke
  end

  it "should call Import::EIC.call" do
    allow(importer).to receive(:call)
    import_class_stub = class_double(Import::EIC).as_stubbed_const(transfer_nested_constants: true)
    allow(import_class_stub).
      to receive(:new).
      with("http://beta.einfracentral.eu", false, false).
      and_return(importer)

    subject.invoke
  end
end
