# frozen_string_literal: true

require "rails_helper"
require "jira/setup"

describe Import::Eic do
  let(:test_url) { "https://localhost" }
  let(:unirest) { double(Unirest) }

  def make_and_stub_eic(ids: [], dry_run: false, dont_create_providers: false, filepath: nil, log: false,
                        default_upstream: nil)
    options = {
        dry_run: dry_run,
        dont_create_providers: dont_create_providers,
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

    eic = Import::Eic.new(test_url, options)

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
  let!(:scientific_domain_other) { create(:scientific_domain, name: "Other") }
  let!(:storage) { create(:category, name: "Storage") }
  let!(:training) { create(:category, name: "Training & Support") }
  let!(:security) { create(:category, name: "Security & Operations") }
  let!(:analytics) { create(:category, name: "Processing & Analysis") }
  let!(:data) { create(:category, name: "Data management") }
  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }

  def expect_responses(unirest, test_url, services_response = nil, providers_response = nil)
    unless services_response.nil?
      expect(unirest).to receive(:get).with("#{test_url}/api/service/rich/all?quantity=10000&from=0",
                                            headers: { "Accept" => "application/json" }).and_return(services_response)
    end

    unless providers_response.nil?
      expect(unirest).to receive(:get).with("#{test_url}/api/provider/all?quantity=10000&from=0",
                                            headers: { "Accept" => "application/json" }).and_return(providers_response)
    end
  end

  describe "#error responses" do
    it "should abort if /api/services errored" do
      response = double(code: 500, body: {})
      expect_responses(unirest, test_url, response)
      expect { log_less_eic.call }.to raise_error(SystemExit).and output.to_stderr
    end

    it "should abort if /api/providers errored" do
      response = double(code: 200, body: create(:eic_services_response))
      provider_response = double(code: 500, body: {})
      expect_responses(unirest, test_url, response, provider_response)
      expect { log_less_eic.call }.to raise_error(SystemExit).and output.to_stderr
    end
  end

  describe "#standard responses" do
    before(:each) do
      response = double(code: 200, body: create(:eic_services_response))
      provider_response = double(code: 200, body: create(:eic_providers_response))
      expect_responses(unirest, test_url, response, provider_response)
    end

    it "should not create if 'dont_create_providers' is set to true" do
      eic = make_and_stub_eic(ids: [], dry_run: false, dont_create_providers: true)
      expect { eic.call }.to change { Provider.count }.by(0)
    end

    it "should create provider if it didn't exist and add external source for it" do
      expect { log_less_eic.call }.to change { Provider.count }.by(4)
      provider = Provider.first

      expect(provider.sources.count).to eq(1)
      expect(provider.sources.first.eid).to eq("bluebridge")
      expect(provider.sources.first.source_type).to eq("eic")
    end

    it "should create service if none existed" do
      trl_7 = create(:trl, name: "trl 7", eid: "trl-7")
      life_cycle_status = create(:life_cycle_status, name: "prod", eid: "production")
      required_resource = create(:service, name: "Super Service",
                                 sources: [build(:service_source, source_type: "eic", eid: "super-service")])
      related_resource = create(:service, name: "Extra Service",
                                sources: [build(:service_source, source_type: "eic", eid: "extra-service")])
      funding_body = create(:funding_body, eid: "funding_body-other", name: "other")
      funding_program = create(:funding_program, eid: "funding_program-other", name: "other")
      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 3, UPDATED: 0, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(3)


      service = Service.third

      expect(service.name).to eq("PhenoMeNal")
      expect(service.description).to eq("PhenoMeNal (Phenome and Metabolome aNalysis) is a comprehensive and standardised " +
                                            "e-infrastructure that supports the data processing and analysis pipelines for molecular " +
                                            "phenotype data generated by metabolomics applications.\n\n")
      expect(service.language_availability).to eq(["EN"])
      expect(service.geographical_availabilities.first.name).to eq("World")
      expect(service.dedicated_for).to eq([])
      expect(service.terms_of_use_url).to eq("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/09/Phenomenal-Terms-of-Use-version-11.pdf")
      expect(service.access_policies_url).to eq("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/09/Phenomenal-Terms-of-Use-version-11.pdf")
      expect(service.sla_url).to eq("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/09/Phenomenal-Terms-of-Use-version-11.pdf")
      expect(service.webpage_url).to eq("https://portal.phenomenal-h2020.eu/home")
      expect(service.manual_url).to eq("https://github.com/phnmnl/phenomenal-h2020/wiki")
      expect(service.helpdesk_url).to eq("http://phenomenal-h2020.eu/home/help")
      expect(service.training_information_url).to eq("http://phenomenal-h2020.eu/home/training-online")
      expect(service.order_type).to eq("open_access")
      expect(service.status).to eq("draft")
      expect(service.providers).to eq([Provider.find_by(name: "Phenomenal"), Provider.find_by(name: "Awesome provider")])
      expect(service.resource_organisation).to eq(Provider.find_by(name: "BlueBRIDGE"))
      expect(service.categories).to eq([])
      expect(service.scientific_domains).to eq([scientific_domain_other])
      expect(service.sources.count).to eq(1)
      expect(service.logo.download).to eq(file_fixture("PhenoMeNal_logo.png").read.b)
      expect(service.sources.first.eid).to eq("phenomenal.phenomenal")
      expect(service.required_services.first).to eq(required_resource)
      expect(service.related_services.first).to eq(related_resource)
      expect(service.upstream_id).to eq(nil)
      expect(service.version).to eq("2018.08")
      expect(service.trl).to eq([trl_7])
      expect(service.life_cycle_status).to eq([life_cycle_status])
      expect(service.status_monitoring_url).to eq("http://phenomenal.eu/monit")
      expect(service.maintenance_url).to eq("http://phenomenal.eu/maintenance")
      expect(service.order_url).to eq("https://portal.phenomenal-h2020.eu/home")
      expect(service.pricing_url).to eq("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/09/Phenomenal-Terms-of-Use-version-11.pdf")
      expect(service.payment_model_url).to eq("http://openminted.eu/payment-model")
      expect(service.funding_bodies).to eq([funding_body])
      expect(service.funding_programs).to eq([funding_program])
      expect(Service.find_by(name: "MetalPDB")).to_not be_nil
      expect(Service.find_by(name: "PDB_REDO server")).to_not be_nil
      expect(service.last_update).to eq(Time.at(1533513600000/1000))
    end

    it "should create an offer for a new services" do
      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 3, UPDATED: 0, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(3).and change { Offer.count }.by(3)
      service = Service.first

      expect(service.offers).to_not be_nil

      offer = service.offers.first

      expect(offer.name).to eq("Offer")
      expect(offer.description).to eq("#{service.name} Offer")
      expect(offer.order_type).to eq("open_access")
      expect(offer.status).to eq(service.status)

      expect(Service.find_by(name: "MetalPDB").offers).to_not be_nil
      expect(Service.find_by(name: "PDB_REDO server").offers).to_not be_nil
    end

    it "should not update service which has upstream to null" do
      service = create(:service)
      create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eic")

      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 0, UPDATED: 0, NOT MODIFIED: 1$/).to_stdout.and change { Service.count }.by(0)
      expect(Service.first.as_json(except: [:created_at, :updated_at])).to eq(service.as_json(except: [:created_at, :updated_at]))
    end

    it "should update service which has upstream to external id" do
      service = create(:service)
      source = create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eic")
      service.update!(upstream_id: source.id)

      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(0)
      expect(Service.first.as_json(except: [:created_at, :updated_at])).to_not eq(service.as_json(except: [:created_at, :updated_at]))
    end

    it "should create an offer for updated services without offers" do
      service = create(:service, status: :published)
      source = create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eic")
      service.update!(upstream_id: source.id)

      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(0).and change { Offer.count }.by(1)
      service.reload
      offer = service.offers.first

      expect(offer.name).to eq("Offer")
      expect(offer.description).to eq("PhenoMeNal Offer")
      expect(offer.order_type).to eq("open_access")
      expect(offer.status).to eq(service.status)
    end

    it "should not create an offer for updated services with offers" do
      service = create(:service, status: :published)
      create(:offer, service: service)
      source = create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eic")
      service.update!(upstream_id: source.id)

      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"], log: true)

      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 0, UPDATED: 1, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(0).and change { Offer.count }.by(0)
    end



    it "should not change db if dry_run is set to true" do
      eic = make_and_stub_eic(dry_run: true, dont_create_providers: false, log: true)
      expect { eic.call }.to output(/PROCESSED: 3, CREATED: 3, UPDATED: 0, NOT MODIFIED: 0$/).to_stdout.and change { Service.count }.by(0).and change { Provider.count }.by(0)
    end

    it "should not update scientific_domains and categories" do
      scientific_domain_something = create(:scientific_domain, name: "Something")

      service = create(:service, categories: [Category.find_by(name: "Networking")], scientific_domains: [scientific_domain_something])
      source = create(:service_source, eid: "phenomenal.phenomenal", service_id: service.id, source_type: "eic")
      service.update!(upstream_id: source.id)

      log_less_eic.call

      expect(Service.first.categories).to eq(service.categories)
      expect(Service.first.scientific_domains).to eq(service.scientific_domains)
    end

    it "should filter by ids if they are provided" do
      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"])
      expect { eic.call }.to change { Service.count }.by(1)
      expect(Service.last.name).to eq("PhenoMeNal")
    end

    # TODO - have to compare image itself
    # it "should convert svg logos to png" do
    #   eic = make_and_stub_eic(["West-Life.pdb_redo_server"])
    #   eic.call
    #   expect(Service.first.logo.download).to eq(open(file_fixture("PDB_logo_rect_medium.png")).read.b)
    # end

    it "should output file with unprocessed data (only selected services)" do
      filename = "eic_output.json"
      mock_file = StringIO.new
      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"], filepath: filename)
      expect(eic).to receive(:open).with(filename, "w").and_yield(mock_file)
      eic.call
      expect(mock_file.string).to eq(file_fixture("eic_import_output.json").read)
    end

    it "should gracefully handle error with logo download" do
      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"])
      allow(eic).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(OpenURI::HTTPError.new("", status: 404))
      eic.call
      expect(Service.first.logo.attached?).to be_falsey
    end

    it "should gracefully handle error with logo download" do
      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"])
      allow(eic).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(Errno::EHOSTUNREACH.new)
      eic.call
      expect(Service.first.logo.attached?).to be_falsey
    end

    it "should gracefully handle error with logo download" do
      eic = make_and_stub_eic(ids: ["phenomenal.phenomenal"])
      allow(eic).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png",
                                        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_raise(StandardError.new)
      eic.call
      expect(Service.first.logo.attached?).to be_falsey
    end
  end

  it "should set placeholder tagline if it's empty" do
    response = double(code: 200, body: create(:eic_services_response, tagline: ""))
    provider_response = double(code: 200, body: create(:eic_providers_response))
    expect_responses(unirest, test_url, response, provider_response)

    eic = make_and_stub_eic(ids: [], dry_run: false, dont_create_providers: false)
    eic.call

    expect(Service.first.tagline).to eq("NO IMPORTED TAGLINE")
  end

  it "should set upstream_id if :eic argument is provided" do
    response = double(code: 200, body: create(:eic_services_response, tagline: ""))
    provider_response = double(code: 200, body: create(:eic_providers_response))
    expect_responses(unirest, test_url, response, provider_response)

    eic = make_and_stub_eic(ids: [], dry_run: false, dont_create_providers: false, default_upstream: :eic)
    eic.call

    service = Service.first
    expect(service.upstream_id).to eq(service.sources.first.id)
  end

  it "should update only EIC fields when importing existing service with EIC upstream" do
    response = double(code: 200, body: create(:eic_services_response, tagline: ""))
    provider_response = double(code: 200, body: create(:eic_providers_response))
    expect_responses(unirest, test_url, response, provider_response)

    make_and_stub_eic(ids: [], dry_run: false, default_upstream: :eic).call

    scientific_domain = create(:scientific_domain)
    service = Service.first
    service.update!(status: "published", scientific_domains: [scientific_domain], categories: [])

    expect_responses(unirest, test_url, response, provider_response)

    make_and_stub_eic(ids: [], dry_run: false, default_upstream: :eic).call
    service.reload
    expect(service.status).to eq("published")
    expect(service.scientific_domains).to eq([scientific_domain])
    expect(service.categories).to eq([])
  end

  it "should match provider by name and connect external source" do
    response = double(code: 200, body: create(:eic_services_response, tagline: ""))
    provider_response = double(code: 200, body: create(:eic_providers_response))
    # create provider with matching name to one returned by provider_response
    provider_phenomenal = create(:provider, name: "Phenomenal")
    provider_awesome = create(:provider, name: "Awesome provider")
    expect_responses(unirest, test_url, response, provider_response)

    make_and_stub_eic(ids: [], dry_run: false, default_upstream: :eic).call

    expect(Service.first.providers).to eq([provider_phenomenal, provider_awesome])
    provider_phenomenal.reload
    provider_awesome.reload
    expect(provider_phenomenal.sources.count).to eq(1)
    expect(provider_awesome.sources.count).to eq(1)
  end

  it "should have correct category mapping" do
    eic.get_db_dependencies

    expect(eic.map_category("storage")).to eq([storage])
    expect(eic.map_category("training")).to eq([training])
    expect(eic.map_category("security")).to eq([security])
    expect(eic.map_category("analytics")).to eq([analytics])
    expect(eic.map_category("data")).to eq([data])
    expect(eic.map_category("compute")).to eq([compute])
    expect(eic.map_category("networking")).to eq([networking])
    expect(eic.map_category("unknown")).to eq([])
  end
end
