# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PcCreateOrUpdate do
  let(:test_url) { "https://localhost/api" }
  let(:logger) { double("Logger").as_null_object }
  let!(:storage) { create(:category, name: "Storage") }
  let!(:training) { create(:category, name: "Training & Support") }
  let!(:security) { create(:category, name: "Security & Operations") }
  let!(:analytics) { create(:category, name: "Processing & Analysis") }
  let!(:data) { create(:category, name: "Data management", eid: "category-data") }
  let!(:data_subcategory) do
    create(:category, name: "Access", parent: data,
                      eid: "subcategory-access")
  end
  let!(:compute) { create(:category, name: "Compute") }
  let!(:networking) { create(:category, name: "Networking") }
  let!(:scientific_domain_other) do
    create(:scientific_domain, name: "Other", eid: "scientific_subdomain-other-other")
  end
  let!(:funding_body) { create(:funding_body, name: "FundingBody", eid: "funding_body-fb") }
  let!(:funding_program) { create(:funding_program, name: "FundingProgram", eid: "funding_program-fp") }
  let!(:related_service) do
    create(:service, name: "Super Service",
                     sources: [build(:service_source, eid: "super-service")])
  end
  let!(:access_mode) { create(:access_mode, name: "Access Mode", eid: "access_mode-am") }
  let!(:access_type) { create(:access_type, name: "Access Type", eid: "access_type-at") }
  let!(:main_contact) do
    build(:main_contact, first_name: "John", last_name: "Doe",
                         email: "john@doe.com",
                         phone: "+41 678 888 123",
                         position: "Developer",
                         organisation: "JD company")
  end
  let!(:public_contacts) do
    build_list(:public_contact, 2) do |contact, i|
      contact.first_name = "Jane #{i}"
      contact.last_name = "Doe"
      contact.email = "jane#{i}@doe.com"
    end
  end

  let(:faraday) { double(Faraday) }
  let(:provider_eid) { "ten" }

  before(:each) do
    provider_response = double(status: 200, body: create(:eosc_registry_provider_response, eid: provider_eid))
    allow_any_instance_of(Importers::Request).to receive(:call).and_return(provider_response)
  end

  describe "#succesfull responses" do
    it "should create new service with new default offer" do
      provider = create(:provider, name: "Test Provider 3")
      provider_tp = create(:provider, name: "Test Provider tp")
      create(:provider_source, source_type: "eosc_registry", eid: "new.prov", provider: provider)

      create(:provider_source, source_type: "eosc_registry", eid: "tp", provider: provider_tp)

      service = create(:jms_service, prov_eid: "new.prov", name: "New supper service")
      expect do
        stub_described_class(service, faraday: faraday)
      end.to change { Offer.count }.by(1)
      offer = Offer.last
      service = Service.last

      expect(offer.name).to eq("Offer")
      expect(offer.description).to eq("#{service.name} Offer")
      expect(offer.order_type).to eq("other")
      expect(offer.status).to eq("published")
      expect(offer.service.id).to eq(service.id)
      expect(service.upstream_id).to eq(service.sources.first.id)
    end
  end

  private

  def stub_described_class(jms_service, is_active: true, modified_at: Date.now, faraday: Faraday)
    described_service = Service::PcCreateOrUpdate.new(jms_service, test_url, is_active, modified_at, nil,
                                                      faraday: faraday)

    stub_http_file(described_service, "PhenoMeNal_logo.png",
                   "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png")

    stub_http_file(described_service, "MetalPDB.png",
                   "http://metalweb.cerm.unifi.it/global/images/MetalPDB.png")

    allow(described_service).to receive(:open).with("http://phenomenal-h2020.eu/home/wp-content/logo.png",
                                                    ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
                                              .and_raise(OpenURI::HTTPError.new("", status: 404))
    described_service.call
  end

  def stub_http_file(service, file_fixture_name, url, content_type: "image/png")
    r = File.open(file_fixture(file_fixture_name))
    r.define_singleton_method(:content_type) { content_type }
    allow(service).to receive(:open).with(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_return(r)
  end
end
