# frozen_string_literal: true

require "rails_helper"
require "jira/setup"
require "ostruct"

describe Import::Providers, backend: true do
  let(:test_url) { "https://localhost/api" }
  let(:faraday) { Faraday }

  def make_and_stub_eosc_registry(ids: [], dry_run: false, filepath: nil, log: false, default_upstream: nil)
    options = { dry_run: dry_run, ids: ids, filepath: filepath, faraday: faraday }

    options[:logger] = ->(_msg) {} unless log

    options[:default_upstream] = default_upstream if default_upstream

    eosc_registry = Import::Providers.new(test_url, **options)

    stub_http_file(
      eosc_registry,
      "PhenoMeNal_logo.png",
      "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png"
    )

    stub_http_file(eosc_registry, "MetalPDB.png", "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png")

    stub_http_file(
      eosc_registry,
      "PDB_logo_rect_medium.svg",
      "https://pdb-redo.eu/images/PDB_logo_rect_medium.svg",
      content_type: "image/svg+xml"
    )

    eosc_registry
  end

  def stub_http_file(eosc_registry, file_fixture_name, url, content_type: "image/png")
    r = File.open(file_fixture(file_fixture_name))
    r.define_singleton_method(:content_type) { content_type }
    allow(eosc_registry).to receive(:open).with(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_return(r)
  end

  let(:eosc_registry) { make_and_stub_eosc_registry(log: true) }
  let(:log_less_eosc_registry) { make_and_stub_eosc_registry(log: false) }
  let!(:scientific_domain_other) { create(:scientific_domain, name: "Other", eid: "scientific_subdomain-other-other") }
  let!(:target_user_other) { create(:target_user, name: "Other", eid: "target_user-other") }
  let!(:storage) { create(:category, name: "Storage") }
  let!(:training) { create(:category, name: "Training & Support") }
  let!(:security) { create(:category, name: "Security & Operations") }
  let!(:analytics) { create(:category, name: "Processing & Analysis") }
  let!(:data) { create(:category, name: "Data management", eid: "category-data") }
  let!(:data_subcategory) { create(:category, name: "Access", eid: "data-applications-software") }

  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }
  let!(:provider) { create(:provider, name: "BlueBRIDGE", pid: "bluebridge") }

  def expect_responses(test_url, providers_response = nil)
    unless providers_response.nil?
      allow_any_instance_of(Faraday::Connection).to receive(:get).with(
        "#{test_url}/public/provider/bundle/all?quantity=10000&from=0"
      ).and_return(providers_response)
    end
  end

  def mock_access_token
    allow_any_instance_of(Faraday::Connection).to(
      receive(:post).with(
        "https://#{ENV["CHECKIN_HOST"] || "aai.eosc-portal.eu"}/auth/realms/core/protocol/openid-connect/token",
        {
          grant_type: "refresh_token",
          refresh_token: nil,
          client_id:
            ENV["IMPORTER_AAI_CLIENT_ID"] || ENV["CHECKIN_IDENTIFIER"] ||
              Rails.application.credentials.checkin[:identifier]
        }
      ).and_return(OpenStruct.new({ body: "{\"access_token\": \"test_token\"}", status: 200 }))
    )
  end

  describe "#error responses" do
    it "should abort if /api/services errored" do
      response = double(status: 500, body: {})
      expect_responses(test_url, response)
      expect { log_less_eosc_registry.call }.to raise_error(SystemExit).and output.to_stderr
    end
  end

  describe "#standard responses" do
    before(:each) do
      response = double(status: 200, body: create(:eosc_registry_providers_response))
      expect_responses(test_url, response)
      mock_access_token
    end

    it "should not update provider which has upstream to null" do
      provider = create(:provider)
      create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eosc_registry")
      provider.update!(upstream_id: nil)

      eosc_registry = make_and_stub_eosc_registry(default_upstream: :mp, ids: ["phenomenal"], log: true)

      expect { eosc_registry.call }.to output(
        /PROCESSED: 1, CREATED: 0, UPDATED: 0, NOT MODIFIED: 1$/
      ).to_stdout.and change { Provider.count }.by(0)
    end

    it "should update provider which has upstream to external id" do
      provider = create(:provider)
      source = create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eosc_registry")
      provider.update!(upstream_id: source.id)

      provider.reload

      eosc_registry = make_and_stub_eosc_registry(ids: ["phenomenal"], log: true)

      expect { eosc_registry.call }.to output(
        /PROCESSED: 1, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/
      ).to_stdout.and change { Provider.count }.by(0)
    end

    it "should not change db if dry_run is set to true" do
      eosc_registry = make_and_stub_eosc_registry(dry_run: true, log: true)
      expect { eosc_registry.call }.to output(
        /PROCESSED: 4, CREATED: 3, UPDATED: 0, NOT MODIFIED: 1$/
      ).to_stdout.and change { Provider.count }.by(0)
    end

    it "should filter by ids if they are provided" do
      eosc_registry = make_and_stub_eosc_registry(ids: ["phenomenal"])
      expect { eosc_registry.call }.to change { Provider.count }.by(1)
      expect(Provider.last.name).to eq("Phenomenal")
    end

    it "should set default image on error" do
      eosc_registry = make_and_stub_eosc_registry(ids: ["phenomenal"])
      allow(eosc_registry).to receive(:open).with(
        "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      ).and_raise(OpenURI::HTTPError.new("", status: 404))
      eosc_registry.call

      expect(Provider.first.logo.attached?).to be_truthy
    end

    it "should set default image on error" do
      eosc_registry = make_and_stub_eosc_registry(ids: ["phenomenal"])
      allow(eosc_registry).to receive(:open).with(
        "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
      ).and_raise(Errno::EHOSTUNREACH.new)
      eosc_registry.call
      expect(Provider.first.logo.attached?).to be_truthy
    end
  end
end
