# frozen_string_literal: true

require "rails_helper"

describe "import:resources", :backend, type: :task do
  let(:resource_importer) { double("Import::Resources") }
  let(:provider_importer) { double("Import::Providers") }

  before do
    # The authorize prerequisite (whitelabel always fetches a token) is covered by import:authorize below.
    allow(Mp::Variant).to receive(:whitelabel?).and_return(false)
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

  it "passes ENV variables" do
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

  it "calls Import::Resources.call" do
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

  it "calls Import::Providers.call" do
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

describe "import:authorize", :backend, type: :task do
  before do
    task.reenable
    allow(Mp::Variant).to receive(:whitelabel?).and_return(false)
  end

  around do |example|
    keys = %w[MP_IMPORT_TOKEN IMPORT_CLIENT_ID IMPORT_CLIENT_SECRET CHECKIN_TOKEN_ENDPOINT]
    original = keys.index_with { |key| ENV.key?(key) ? ENV[key] : nil }
    example.run
  ensure
    keys.each { |key| original[key].nil? ? ENV.delete(key) : ENV[key] = original[key] }
  end

  after { task.reenable }

  it "sets MP_IMPORT_TOKEN from complete client credentials" do
    ENV.delete("MP_IMPORT_TOKEN")
    ENV["IMPORT_CLIENT_ID"] = "import-client"
    ENV["IMPORT_CLIENT_SECRET"] = "import-secret"
    ENV["CHECKIN_TOKEN_ENDPOINT"] = "https://checkin.example/token"
    token_importer = instance_double(Importers::ClientCredentialsToken, receive_token: "received-token")
    allow(Importers::ClientCredentialsToken).to receive(:new).and_return(token_importer)

    task.invoke

    expect(ENV.fetch("MP_IMPORT_TOKEN", nil)).to eq("received-token")
  end

  it "keeps an explicitly supplied token" do
    ENV["MP_IMPORT_TOKEN"] = "manual-token"
    ENV["IMPORT_CLIENT_ID"] = "import-client"
    ENV["IMPORT_CLIENT_SECRET"] = "import-secret"

    expect(Importers::ClientCredentialsToken).not_to receive(:new)

    task.invoke

    expect(ENV.fetch("MP_IMPORT_TOKEN", nil)).to eq("manual-token")
  end

  context "when whitelabel has no token and no import client credentials" do
    let(:token_importer) { instance_double(Importers::ClientCredentialsToken, receive_token: "received-token") }

    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Importers::ClientCredentialsToken).to receive(:new).and_return(token_importer)
      ENV.delete("MP_IMPORT_TOKEN")
      ENV.delete("IMPORT_CLIENT_ID")
      ENV.delete("IMPORT_CLIENT_SECRET")
      task.invoke
    end

    it "still fetches a client credentials token" do
      expect(ENV.fetch("MP_IMPORT_TOKEN", nil)).to eq("received-token")
    end
  end

  context "when whitelabel has a blank token" do
    let(:token_importer) { instance_double(Importers::ClientCredentialsToken, receive_token: "received-token") }

    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Importers::ClientCredentialsToken).to receive(:new).and_return(token_importer)
      ENV["MP_IMPORT_TOKEN"] = ""
      task.invoke
    end

    it "replaces it with a client credentials token" do
      expect(ENV.fetch("MP_IMPORT_TOKEN", nil)).to eq("received-token")
    end
  end

  context "when whitelabel has an explicitly supplied token" do
    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Importers::ClientCredentialsToken).to receive(:new)
      ENV["MP_IMPORT_TOKEN"] = "manual-token"
      task.invoke
    end

    it "keeps the token" do
      expect(ENV.fetch("MP_IMPORT_TOKEN", nil)).to eq("manual-token")
    end

    it "does not request another one" do
      expect(Importers::ClientCredentialsToken).not_to have_received(:new)
    end
  end

  context "when whitelabel cannot fetch the token" do
    let(:token_importer) { instance_double(Importers::ClientCredentialsToken) }

    before do
      allow(Mp::Variant).to receive(:whitelabel?).and_return(true)
      allow(Importers::ClientCredentialsToken).to receive(:new).and_return(token_importer)
      allow(token_importer).to receive(:receive_token).and_raise(
        Importers::ClientCredentialsToken::RequestError,
        "Access token request failed: boom"
      )
      ENV.delete("MP_IMPORT_TOKEN")
    end

    it "propagates the error" do
      expect { task.invoke }.to raise_error(
        Importers::ClientCredentialsToken::RequestError,
        "Access token request failed: boom"
      )
    end
  end
end
