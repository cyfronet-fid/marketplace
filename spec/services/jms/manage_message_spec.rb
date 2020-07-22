# frozen_string_literal: true

require "rails_helper"
require "stomp"
require "nori"

describe Jms::ManageMessage do
  let(:eic_base) { "localhost" }
  let(:logger) { Logger.new($stdout) }
  let(:parser) { Nori.new(strip_namespaces: true) }
  let(:service_resource) { create(:jms_xml_service) }
  let(:provider_resource) { create(:jms_xml_provider) }
  let(:json_service) { double(body: service_resource.to_json,
                              headers: { "destination"=> "/topic/registry.infra_service.update" }) }
  let(:json_provider) { double(body: provider_resource.to_json,
                               headers: { "destination"=> "/topic/registry.infra_service.update" }) }
  let(:service_create_or_update) { instance_double(Service::PcCreateOrUpdate) }
  let(:provider_create_or_update) { instance_double(Provider::PcCreateOrUpdate) }

  it "should receive service message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect(Service::PcCreateOrUpdateJob).to receive(:perform_later).with(parser.parse(service_resource["resource"])["infraService"]["service"],
                                                                         eic_base,
                                                                         true)
    expect {
      described_class.new(json_service, eic_base, logger).call
    }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(parser.parse(provider_resource["resource"])["providerBundle"]["provider"])

    expect {
      described_class.new(json_provider, eic_base, logger).call
    }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive service delete message" do
    service = create(:service)
    create(:service_source, service: service, eid: "tp.openminted_catalogue_of_corpora_2")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_service  =  double(body: service_resource.to_json,
                            headers: { "destination"=> "/topic/registry.infra_service.delete" })
    expect(Service::DeleteJob).to receive(:perform_later).with("tp.openminted_catalogue_of_corpora_2")

    expect {
      described_class.new(json_service, eic_base, logger).call
    }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive error if message is invalid" do
    original_stdout = $stdout
    $stdout = StringIO.new
    service_hash = { "some_happy_key": "some_happy_value" }
    error_service_message = double(body: service_hash.to_json, headers: { "destination" => "aaaa.update" })

    expect {
      described_class.new(error_service_message, eic_base, logger).call
    }.to raise_error(StandardError)
    $stdout = original_stdout
  end
end
