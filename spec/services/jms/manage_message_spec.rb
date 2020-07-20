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
  let(:json_service) { double(body: service_resource.to_json) }
  let(:json_provider) { double(body: provider_resource.to_json) }
  let(:service_create_or_update) { instance_double(Service::PcCreateOrUpdate) }
  let(:provider_create_or_update) { instance_double(Provider::PcCreateOrUpdate) }

  it "should receive service message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    allow(Service::PcCreateOrUpdate).to receive(:new).with(parser.parse(service_resource["resource"])["infraService"]["service"],
                                                            eic_base,
                                                            true).and_return(service_create_or_update)
    allow(service_create_or_update).to receive(:call).and_return(true)
    expect {
      described_class.new(json_service, eic_base, logger).call
    }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    allow(Provider::PcCreateOrUpdate).to receive(:new).with(parser.parse(provider_resource["resource"])["providerBundle"]["provider"])
                                                            .and_return(provider_create_or_update)
    allow(provider_create_or_update).to receive(:call).and_return(true)

    expect {
      described_class.new(json_provider, eic_base, logger).call
    }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive error and unreceive if service cannot be created" do
    original_stdout = $stdout
    $stdout = StringIO.new
    service_hash = { "resource": "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"+
                                   "<tns:infraService xmlns:tns=\"http://einfracentral.eu\">" +
                                   "<tns:latest>true</tns:latest>" +
                                   "<tns:service></tns:service>" +
                                   "</tns:infraService>",
                     "resourceType": "infra_service" }
    allow(Service::PcCreateOrUpdate).to receive(:new).with(parser.parse(service_hash[:resource])["infraService"]["service"],
                                                           eic_base,
                                                           true).and_return(service_create_or_update)
    allow(service_create_or_update).to receive(:call).and_raise(StandardError)

    expect {
      described_class.new(double(body: service_hash), eic_base, logger).call
    }.to raise_error(StandardError)
    $stdout = original_stdout
  end

  it "should receive error and unreceive if provider cannot be created" do
    original_stdout = $stdout
    $stdout = StringIO.new
    provider_hash = { "resource": "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"+
                                   "<tns:provider xmlns:tns=\"http://einfracentral.eu\">" +
                                   "<tns:active>true</tns:active>" +
                                   "</tns:provider>",
                     "resourceType": "provider" }

    allow(Provider::PcCreateOrUpdate).to receive(:new).with(parser.parse(provider_hash[:resource])["provider"])
      .and_return(provider_create_or_update)

    allow(provider_create_or_update).to receive(:call).and_raise(StandardError)

    expect {
      described_class.new(double(body: provider_hash), eic_base, logger).call
    }.to raise_error(StandardError)
    $stdout = original_stdout
  end

  it "should receive error if message is invalid" do
    original_stdout = $stdout
    $stdout = StringIO.new
    service_hash = { "some_happy_key": "some_happy_value" }
    error_service_message = double(body: service_hash.to_json)

    expect {
      described_class.new(error_service_message, eic_base, logger).call
    }.to raise_error(StandardError)
    $stdout = original_stdout
  end
end
