# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PcCreateOrUpdate do
  let(:test_url) { "https://localhost" }
  let(:logger) { double("Logger").as_null_object }
  let!(:storage) { create(:category, name: "Storage") }
  let!(:training) { create(:category, name: "Training & Support") }
  let!(:security) { create(:category, name: "Security & Operations") }
  let!(:analytics) { create(:category, name: "Processing & Analysis") }
  let!(:data) { create(:category, name: "Data management") }
  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }
  let!(:scientific_domain_other) { create(:scientific_domain, name: "Other") }
  let!(:funding_body) { create(:funding_body, name: "FundingBody", eid: "funding_body-fb") }
  let!(:funding_program) { create(:funding_program, name: "FundingProgram", eid: "funding_program-fp") }

  let(:unirest) { double(Unirest) }
  let(:provider_eid) { "ten" }

  describe "#succesfull responses" do
    it "should create new service with all informations" do
      trl_8 = create(:trl, name: "trl 7", eid: "trl-8")
      life_cycle_status = create(:life_cycle_status, name: "prod", eid: "production")
      unirest = Unirest
      provider_response = double(code: 200, body: create(:eic_provider_response))

      expect(unirest).to receive(:get).with("#{test_url}/api/provider/#{provider_eid}",
                                            headers: { "Accept" => "application/json" }).and_return(provider_response)

      service = stub_described_class(create(:jms_service, prov_eid: provider_eid), unirest: unirest)

      expect(service.name).to eq("Title")
      expect(service.description).to eq("A catalogue of corpora (datasets) made up of mainly " +
                                        "Open Access scholarly publications. Users can view publicly available corpora that " +
                                        "have been created with the OpenMinTeD Corpus Builder for Scholarly Works, or manually uploaded " +
                                        "to the OpenMinTeD platform.&nbsp; The catalogue can be " +
                                        "browsed and searched via the faceted navigation facility or a google-like free text search query. " +
                                        "All users can view the descriptions of the corpora (with administrative and technical information, "+
                                        "such as language, domain, keywords, licence, resource creator, etc.), as well as the contents and, " +
                                        "when available, the metadata descriptions of the individual files that compose them.&nbsp; " +
                                        "In addition, registered users can process them with the TDM " +
                                        "applications offered by OpenMinTeD and download them in accordance with their licensing conditions.\n\n\n" +
                                        "Standard\nFor users interested in finding corpora of various languages and domains easily accessible and " +
                                        "ready to be processed with TDM applications; the use of a uniform metadata schema for their description " +
                                        "facilitates comparison and contrast and thereby selection of the appropriate corpus.\n")

      expect(service.tagline).to eq("Find easily accessible corpora of scholarly content and mine them!")
      expect(service.places).to eq("World")
      expect(service.language_availability).to eq(["english"])
      expect(service.dedicated_for).to eq([])
      expect(service.terms_of_use_url).to eq("https://services.openminted.eu/support/termsAndConditions")
      expect(service.access_policies_url).to eq("http://openminted.eu/pricing/")
      expect(service.sla_url).to eq("http://openminted.eu/sla-agreement/")
      expect(service.webpage_url).to eq("http://openminted.eu/omtd-services/catalogue-of-scholarly-datasets/")
      expect(service.manual_url).to eq("http://openminted.eu/user-manual/")
      expect(service.helpdesk_url).to eq("https://services.openminted.eu/support")
      expect(service.training_information_url).to eq("http://openminted.eu/support-training/")
      expect(service.phase).to eq("production")
      expect(service.order_type).to eq("open_access")
      expect(service.funding_bodies).to eq([funding_body])
      expect(service.funding_programs).to eq([funding_program])
      expect(service.status).to eq("published")
      expect(service.providers).to eq([Provider.first])
      expect(service.categories).to eq([])
      expect(service.scientific_domains).to eq([scientific_domain_other])
      expect(service.sources.count).to eq(1)
      expect(service.logo.download).to eq(file_fixture("PhenoMeNal_logo.png").read.b)
      expect(service.sources.first.eid).to eq("first.service")
      expect(service.upstream_id).to eq(nil)
      expect(service.version).to eq("1.0")
      expect(service.trl).to eq([trl_8])
      expect(service.life_cycle_status).to eq([life_cycle_status])
    end

    it "should create new service with new provider" do
      unirest = Unirest
      provider_response = double(code: 200, body: create(:eic_provider_response))

      expect(unirest).to receive(:get).with("#{test_url}/api/provider/#{provider_eid}",
                                            headers: { "Accept" => "application/json" }).and_return(provider_response)

      service = stub_described_class(create(:jms_service, prov_eid: provider_eid), unirest: unirest)

      last_provider = Provider.last

      expect(service.providers).to include(last_provider)
      expect(last_provider.name).to eq("Test Provider 2")
    end

    it "should create new service with existed provider" do
      provider = create(:provider, name: "Test Provider 3")
      create(:provider_source, source_type: "eic", eid: "new.prov", provider: provider)

      service = stub_described_class(create(:jms_service, prov_eid: "new.prov", name: "New supper service"), unirest: unirest)
      last_service = Service.last
      expect(last_service.name).to eq("New supper service")
      expect(service.providers[0].name).to eq("Test Provider 3")
    end

    it "should create new service with new default offer" do
      provider = create(:provider, name: "Test Provider 3")
      create(:provider_source, source_type: "eic", eid: "new.prov", provider: provider)
      service = create(:jms_service, prov_eid: "new.prov", name: "New supper service")
      expect {
        stub_described_class(service, unirest: unirest)
      }.to change { Offer.count }.by(1)
      offer = Offer.last
      service = Service.last

      expect(offer.name).to eq("Offer")
      expect(offer.description).to eq("#{service.name} Offer")
      expect(offer.order_type).to eq("open_access")
      expect(offer.status).to eq(service.status)
      expect(offer.service.id).to eq(service.id)
    end

    it "should update logo" do
      provider = create(:provider, name: "Test Provider 2")
      create(:provider_source, source_type: "eic", eid: provider_eid, provider: provider)

      service = create(:service, providers: [provider])

      create(:service_source, source_type: "eic", eid: "first.service", service: service)

      service = stub_described_class(create(:jms_service, name: "New title",
                                            logo: "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png",
                                            prov_eid: provider_eid))
      expect(service.name).to eq("New title")
      expect(service.logo.download).to eq(file_fixture("MetalPDB.png").read.b)
    end

    it "should update service" do
      provider = create(:provider, name: "Test Provider 2")
      create(:provider_source, source_type: "eic", eid: provider_eid, provider: provider)
      service = create(:service, providers: [provider])

      create(:service_source, source_type: "eic", eid: "first.service", service: service)

      service = stub_described_class(create(:jms_service, name: "New title", prov_eid: provider_eid))
      expect(service.name).to eq("New title")
    end
  end

  context "#failed response" do
    it "should abort if /api/provider errored" do
      unirest = Unirest
      service = create(:jms_service, prov_eid: "new2")
      provider_response = double(code: 500, body: {})

      expect(unirest).to receive(:get).with("#{test_url}/api/provider/new2",
                                            headers: { "Accept" => "application/json" }).and_return(provider_response)

      expect { stub_described_class(service, unirest: unirest) }.to raise_error(SystemExit).and output.to_stderr
    end

    it "should gracefully handle error with logo download" do
      provider = create(:provider, name: "Test Provider 3")
      create(:provider_source, source_type: "eic", eid: "new", provider: provider)
      unirest = Unirest
      jms_service = create(:jms_service, logo: "http://phenomenal-h2020.eu/home/wp-content/logo.png")

      stub_described_class(jms_service, unirest: unirest)

      expect(Service.first.logo.attached?).to be_falsey
    end
  end



  private
    def stub_described_class(jms_service, unirest: Unirest)
      described_service = Service::PcCreateOrUpdate.new(jms_service, test_url, logger, unirest: unirest)

      stub_http_file(described_service, "PhenoMeNal_logo.png",
                     "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png")

      stub_http_file(described_service, "MetalPDB.png",
                     "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png")

      allow(described_service).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(OpenURI::HTTPError.new("", status: 404))
      described_service.call
    end

    def stub_http_file(service, file_fixture_name, url, content_type: "image/png")
      r = open(file_fixture(file_fixture_name))
      r.define_singleton_method(:content_type) { content_type }
      allow(service).to receive(:open).with(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_return(r)
    end
end
