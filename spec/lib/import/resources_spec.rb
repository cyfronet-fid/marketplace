# frozen_string_literal: true

require "rails_helper"
require "jira/setup"
require "ostruct"

describe Import::Resources, backend: true do
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

  let(:eosc_registry) { Import::Resources.new(test_url, **eosc_registry_options) }

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
  let!(:other_category) { create(:service_category, name: "Other", eid: "service-category_other") }

  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }
  let!(:provider) { create(:provider, name: "BlueBRIDGE", pid: "bluebridge") }
  let!(:second_provider) { create(:provider, name: "Prov", pid: "awesome") }

  def expect_responses(test_url, services_response = nil)
    unless services_response.nil?
      allow_any_instance_of(Faraday::Connection).to receive(:get).with(
        "#{test_url}/public/service/all?quantity=10000&from=0"
      ).and_return(services_response)
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
      response = double(status: 200, body: create(:eosc_registry_services_response))
      expect_responses(test_url, response)
      mock_access_token
    end

    context "with default options" do
      let(:log) { true }

      it "shouldn't create an offer for a new services" do
        expect { eosc_registry.call }.to output(
          /PROCESSED: 3, CREATED: 3, UPDATED: 0, NOT MODIFIED: 0$/
        ).to_stdout.and change { Service.count }.by(1)
        service = Service.first

        expect(service.offers).to be_empty
      end
    end

    context "when service has upstream set to null" do
      let(:ids) { ["phenomenal.phenomenal"] }
      let(:log) { true }

      it "should not update service which has upstream to null" do
        service = create(:service)
        create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eosc_registry")

        expect { eosc_registry.call }.to output(
          /PROCESSED: 3, CREATED: 0, UPDATED: 0, NOT MODIFIED: 1$/
        ).to_stdout.and change { Service.count }.by(0)
        expect(Service.first.as_json(except: %i[created_at updated_at])).to eq(
          service.as_json(except: %i[created_at updated_at])
        )
      end
    end

    context "when service has upstream set to an external id" do
      let(:ids) { ["phenomenal.phenomenal"] }
      let(:log) { true }

      it "should update service which has upstream to external id and repeated providers" do
        service = create(:service, order_type: :other)
        create(:other_offer, service: service)
        source =
          create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eosc_registry")
        service.update!(upstream_id: source.id)

        service.reload

        expect { eosc_registry.call }.to output(
          /PROCESSED: 3, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/
        ).to_stdout.and change { Service.count }.by(0)

        service.reload

        expect(Service.first.as_json(except: %i[created_at updated_at])).to eq(
          service.as_json(except: %i[created_at updated_at])
        )
      end

      it "should not create an offer for updated services with offers" do
        service = create(:service, status: :published)
        create(:offer, service: service)
        source =
          create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eosc_registry")
        service.update!(upstream_id: source.id)

        expect { eosc_registry.call }.to output(
          /PROCESSED: 3, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/
        ).to_stdout.and change { Service.count }.by(0).and change { Offer.count }.by(0)
      end
    end

    context "when dry_run is set to true" do
      let(:dry_run) { true }
      let(:log) { true }

      it "should not change db" do
        expect { eosc_registry.call }.to output(
          /PROCESSED: 3, CREATED: 3, UPDATED: 0, NOT MODIFIED: 0$/
        ).to_stdout.and change { Service.count }.by(0).and change { Provider.count }.by(0)
      end
    end

    context "when ids are provided" do
      let(:ids) { ["phenomenal.phenomenal"] }

      it "should filter by ids" do
        expect { eosc_registry.call }.to change { Service.count }.by(1)
        expect(Service.last.name).to eq("PhenoMeNal")
      end

      it "preserves inactive service status from the registry" do
        response_body = create(:eosc_registry_services_response)
        response_body.dig("results", 0, "service")["active"] = false
        response_body.dig("results", 0, "service")["suspended"] = false
        expect_responses(test_url, double(status: 200, body: response_body))

        expect { eosc_registry.call }.to change { Service.count }.by(1)
        expect(Service.find_by(pid: "phenomenal.phenomenal")).to be_unpublished
      end

      it "preserves suspended service status from the registry" do
        response_body = create(:eosc_registry_services_response)
        response_body.dig("results", 0, "service")["active"] = true
        response_body.dig("results", 0, "service")["suspended"] = true
        expect_responses(test_url, double(status: 200, body: response_body))

        expect { eosc_registry.call }.to change { Service.count }.by(1)
        expect(Service.find_by(pid: "phenomenal.phenomenal")).to be_suspended
      end

      it "publishes a V6 service without scientific domains" do
        response_body = create(:eosc_registry_services_response)
        service_payload = response_body.dig("results", 0, "service")
        service_payload["scientificDomains"] = nil
        expect_responses(test_url, double(status: 200, body: response_body))

        expect { eosc_registry.call }.to change { Service.count }.by(1)
        service = Service.find_by!(pid: "phenomenal.phenomenal")
        expect(service).to be_published
        expect(service.scientific_domains).to be_empty
      end

      it "should gracefully handle 404 status with logo download" do
        mock_uri = double
        expect(URI).to receive(:parse).with(
          "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png"
        ).and_return(mock_uri)
        allow(URI).to receive(:parse).and_call_original
        expect(mock_uri).to receive(:open).with(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(
          OpenURI::HTTPError.new("", status: 404)
        )
        eosc_registry.call
        expect(Service.first.logo.attached?).to be_falsey
      end

      it "should gracefully handle unreachable host error with logo download" do
        mock_uri = double
        expect(URI).to receive(:parse).with(
          "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png"
        ).and_return(mock_uri)
        allow(URI).to receive(:parse).and_call_original
        expect(mock_uri).to receive(:open).with(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(
          Errno::EHOSTUNREACH.new
        )
        eosc_registry.call
        expect(Service.first.logo.attached?).to be_falsey
      end
    end

    context "when filepath is provided" do
      let(:ids) { ["phenomenal.phenomenal"] }
      let(:filepath) { "eosc_registry_output.json" }

      it "should output file with unprocessed data (only selected services)" do
        mock_file = StringIO.new
        expect(File).to receive(:open).with(filepath, "w").and_yield(mock_file)
        allow(File).to receive(:open).and_call_original
        eosc_registry.call
        expect(JSON.parse(mock_file.string)).to eq(JSON.parse(file_fixture("eosc_registry_import_output.json").read))
      end
    end
  end
end
