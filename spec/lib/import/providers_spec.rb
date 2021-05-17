# frozen_string_literal: true

require "rails_helper"
require "jira/setup"

describe Import::Providers do
  let(:test_url) { "https://localhost/api" }
  let(:unirest) { double(Unirest) }

  def make_and_stub_eic(ids: [], dry_run: false, filepath: nil, log: false, default_upstream: nil)
    options = {
      dry_run: dry_run,
      ids: ids,
      filepath: filepath,
      unirest: unirest
    }

    unless log
      options[:logger] = ->(_msg) { }
    end

    if default_upstream
      options[:default_upstream] = default_upstream
    end

    eic = Import::Providers.new(test_url, options)

    def stub_http_file(eic, file_fixture_name, url, content_type: "image/png")
      r = open(file_fixture(file_fixture_name))
      r.define_singleton_method(:content_type) { content_type }
      allow(eic).to receive(:open).with(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_return(r)
    end

    stub_http_file(eic, "PhenoMeNal_logo.png",
                   "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png")

    stub_http_file(eic, "MetalPDB.png",
                   "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png")

    stub_http_file(eic, "PDB_logo_rect_medium.svg",
                   "https://pdb-redo.eu/images/PDB_logo_rect_medium.svg",
                   content_type: "image/svg+xml")

    eic
  end

  let(:eic) { make_and_stub_eic(log: true) }
  let(:log_less_eic) { make_and_stub_eic(log: false) }
  let!(:scientific_domain_other) { create(:scientific_domain, name: "Other",
                                          eid: "scientific_subdomain-other-other") }
  let!(:target_user_other) { create(:target_user, name: "Other", eid: "target_user-other") }
  let!(:storage) { create(:category, name: "Storage") }
  let!(:training) { create(:category, name: "Training & Support") }
  let!(:security) { create(:category, name: "Security & Operations") }
  let!(:analytics) { create(:category, name: "Processing & Analysis") }
  let!(:data) { create(:category, name: "Data management", eid: "category-data") }
  let!(:data_subcategory) { create(:category, name: "Access", eid: "data-applications-software") }

  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }
  let!(:provider) { create(:provider, name: "BlueBRIDGE") }

  def expect_responses(unirest, test_url, providers_response = nil)
    unless providers_response.nil?
      expect(unirest).to receive(:get).with("#{test_url}/provider/all?quantity=10000&from=0",
                                            headers: { "Accept" => "application/json" }).and_return(providers_response)
    end
  end

  describe "#error responses" do
    it "should abort if /api/services errored" do
      response = double(code: 500, body: {})
      expect_responses(unirest, test_url, response)
      expect { log_less_eic.call }.to raise_error(SystemExit).and output.to_stderr
    end
  end

  describe "#standard responses" do
    before(:each) do
      response = double(code: 200, body: create(:eic_providers_response))
      expect_responses(unirest, test_url, response)
    end

    it "should not update provider which has upstream to null" do
      provider = create(:provider)
      create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eic")

      eic = make_and_stub_eic(ids: ["phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 1, CREATED: 0, UPDATED: 0, NOT MODIFIED: 1$/).to_stdout.and change { Provider.count }.by(0)
    end

    it "should update provider which has upstream to external id" do
      provider = create(:provider)
      source = create(:provider_source, eid: "phenomenal", provider_id: provider.id, source_type: "eic")
      provider.update!(upstream_id: source.id)

      provider.reload

      eic = make_and_stub_eic(ids: ["phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 1, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/).to_stdout.and change { Provider.count }.by(0)
    end

    it "should not change db if dry_run is set to true" do
      eic = make_and_stub_eic(dry_run: true, log: true)
      expect { eic.call }.to output(/PROCESSED: 4, CREATED: 3, UPDATED: 0, NOT MODIFIED: 1$/).to_stdout.and change { Provider.count }.by(0)
    end

    it "should filter by ids if they are provided" do
      eic = make_and_stub_eic(ids: ["phenomenal"])
      expect { eic.call }.to change { Provider.count }.by(1)
      expect(Provider.last.name).to eq("Phenomenal")
    end

    it "should set default image on error" do
      eic = make_and_stub_eic(ids: ["phenomenal"])
      allow(eic).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(OpenURI::HTTPError.new("", status: 404))
      eic.call

      expect(Provider.first.logo.attached?).to be_truthy
    end

    it "should set default image on error" do
      eic = make_and_stub_eic(ids: ["phenomenal"])
      allow(eic).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(Errno::EHOSTUNREACH.new)
      eic.call
      expect(Provider.first.logo.attached?).to be_truthy
    end
  end
end
