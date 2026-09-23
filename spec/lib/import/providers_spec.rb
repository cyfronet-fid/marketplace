# frozen_string_literal: true

require "rails_helper"
require "jira/setup"
require "ostruct"

describe Import::Providers, backend: true do
  let(:test_url) { "https://localhost/api" }
  let(:faraday) { Faraday }

  let(:ids) { [] }
  let(:dry_run) { false }
  let(:filepath) { nil }
  let(:default_upstream) { nil }
  let(:log) { false }

  let(:eosc_registry_options) do
    options = { dry_run: dry_run, ids: ids, filepath: filepath, faraday: faraday }
    options[:logger] = ->(_msg) {} unless log
    options[:default_upstream] = default_upstream if default_upstream
    options
  end

  let(:eosc_registry) { Import::Providers.new(test_url, **eosc_registry_options) }

  before do
    stub_request(:get, "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png").to_return(
      status: 200,
      body: File.binread(file_fixture("PhenoMeNal_logo.png")),
      headers: { "Content-Type" => "image/png" }
    )

    stub_request(:get, "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png").to_return(
      status: 200,
      body: File.binread(file_fixture("MetalPDB.png")),
      headers: { "Content-Type" => "image/png" }
    )

    stub_request(:get, "https://pdb-redo.eu/images/PDB_logo_rect_medium.svg").to_return(
      status: 200,
      body: File.binread(file_fixture("PDB_logo_rect_medium.svg")),
      headers: { "Content-Type" => "image/svg+xml" }
    )
  end

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
        "#{test_url}/public/organisation/all?quantity=10000&from=0"
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
      mock_access_token
      expect { eosc_registry.call }.to raise_error(SystemExit).and output.to_stderr
    end
  end

  describe "#standard responses" do
    before(:each) do
      body = create(:eosc_registry_providers_response)
      body["results"] = body["results"].map do |provider_bundle|
        provider_bundle["provider"].merge(
          "active" => provider_bundle["active"],
          "suspended" => provider_bundle["suspended"] || false,
          "country" => provider_bundle.dig("provider", "location", "country")
        )
      end
      response = double(status: 200, body: body)
      expect_responses(test_url, response)
      mock_access_token
    end

    context "when provider has upstream set to null" do
      let(:default_upstream) { :mp }
      let(:ids) { ["phenomenal"] }
      let(:log) { true }

      it "should not update provider which has upstream to null" do
        provider = create(:provider)
        create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eosc_registry")
        provider.update!(upstream_id: nil)

        expect { eosc_registry.call }.to output(
          /PROCESSED: 1, CREATED: 0, UPDATED: 0, NOT MODIFIED: 1$/
        ).to_stdout.and change { Provider.count }.by(0)
      end
    end

    context "when provider has upstream set to an external id" do
      let(:ids) { ["phenomenal"] }
      let(:log) { true }

      it "should update provider which has upstream to external id" do
        provider = create(:provider)
        source = create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eosc_registry")
        provider.update!(upstream_id: source.id)

        provider.reload

        expect { eosc_registry.call }.to output(
          /PROCESSED: 1, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/
        ).to_stdout.and change { Provider.count }.by(0)
      end
    end

    context "when dry_run is set to true" do
      let(:dry_run) { true }
      let(:log) { true }

      it "should not change db" do
        expect { eosc_registry.call }.to output(
          /PROCESSED: 4, CREATED: 3, UPDATED: 0, NOT MODIFIED: 1$/
        ).to_stdout.and change { Provider.count }.by(0)
      end
    end

    context "when ids are provided" do
      let(:ids) { ["phenomenal"] }

      it "should filter by ids" do
        expect { eosc_registry.call }.to change { Provider.count }.by(1)
        expect(Provider.last.name).to eq("Phenomenal")
      end

      it "should set default image on error" do
        eosc_registry.call

        expect(Provider.first.logo.attached?).to be_truthy
      end
    end
  end
end
