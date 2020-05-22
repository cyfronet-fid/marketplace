# frozen_string_literal: true

require "rails_helper"
require "jms/subscriber"
require "stomp"
require "nori"

describe Jms::Subscriber do
  let(:parser) { Nori.new(strip_namespaces: true) }
  let(:client) { double("Stomp::Client", config_hash) }
  let(:client_stub) { class_double(Stomp::Client)
                      .as_stubbed_const(transfer_nested_constants: true)}
  let(:service_resource) { create(:jms_xml_service) }
  let(:provider_resource) { create(:jms_xml_provider) }
  let(:json_service) { double(body: service_resource.to_json) }
  let(:json_provider) { double(body: provider_resource.to_json) }
  let(:connection) { double("connection",
                           :autoflush= => true,
                           :login => "dummy_login",
                           :passcode => "dummy_pass",
                           :port => 12345,
                           :host => "dummy_host",
                           :ssl => "false") }
  let(:service_create_or_update) { instance_double(Service::PcCreateOrUpdate) }
  let(:provider_create_or_update) { instance_double(Provider::PcCreateOrUpdate) }

  def mock_subscriber
    $stdout = StringIO.new
    logger = Logger.new($stdout)

    allow_any_instance_of(Jms::Subscriber).to receive(:conf_hash)
                                              .with("dummy_login", "dummy_pass", "dummy_host")
                                              .and_return(config_hash)

    allow(client_stub).to receive(:new).and_return(client)
    sub = Jms::Subscriber.new("dummy_topic",
                              "dummy_login",
                              "dummy_pass",
                              "dummy_host",
                              "localhost",
                              client: client_stub,
                              logger: logger)
    sub
  end

  def stub_good_message
    allow(client).to receive(:subscribe).with("/topic/dummy_topic.>",
                                              { "ack": "client-individual",
                                                "activemq.subscriptionName": "mpSubscription" })
                                                .and_yield(json_service)

    allow(client).to receive(:ack).with(json_service)
    allow(Service::PcCreateOrUpdate).to receive(:new).with(parser.parse(service_resource["resource"])["infraService"], "localhost").and_return(service_create_or_update)
    allow(service_create_or_update).to receive(:call).and_return(true)
  end

  it "should receive service message" do
    stub_good_message

    allow(client).to receive(:open?).and_return(true)
    allow(client).to receive(:connection_frame).and_return(double(command: nil))
    allow(client).to receive(:join).and_return(true)

    subscriber = mock_subscriber
    expect {
      subscriber.run
    }.to_not raise_error
  end

  it "should receive provider message" do
    allow(client).to receive(:subscribe).with("/topic/dummy_topic.>",
                                              { "ack": "client-individual",
                                                "activemq.subscriptionName": "mpSubscription" })
                                                .and_yield(json_provider)

    allow(client).to receive(:ack).with(json_provider)
    allow(Provider::PcCreateOrUpdate).to receive(:new).with(parser.parse(provider_resource["resource"])["provider"]).and_return(provider_create_or_update)
    allow(client).to receive(:open?).and_return(true)
    allow(client).to receive(:connection_frame).and_return(double(command: nil))
    allow(client).to receive(:join).and_return(true)

    allow(provider_create_or_update).to receive(:call).and_return(true)
    subscriber = mock_subscriber

    expect {
      subscriber.run
    }.to_not raise_error
  end

  it "should receive error and unreceive if service cannot be created" do
    service_hash = { "resource": "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"+
                                   "<tns:infraService xmlns:tns=\"http://einfracentral.eu\">" +
                                   "<tns:latest>true</tns:latest>" +
                                   "</tns:infraService>",
                     "resourceType": "infra_service" }
    error_service_message = double(body: service_hash.to_json)
    allow(client).to receive(:subscribe).with("/topic/dummy_topic.>",
                                              { "ack": "client-individual",
                                                "activemq.subscriptionName": "mpSubscription" })
                                                .and_yield(error_service_message)

    service_instance = instance_double(Service::PcCreateOrUpdate)
    allow(Service::PcCreateOrUpdate).to receive(:new).with(parser.parse(service_hash[:resource])["infraService"], "localhost")
      .and_return(service_instance)

    allow(service_instance).to receive(:call).and_raise(StandardError)
    subscriber = mock_subscriber
    expect(client).to receive(:unreceive).with(error_service_message)
    expect {
      subscriber.run
    }.to raise_error(SystemExit)
  end

  it "should receive error and unreceive if provider cannot be created" do
    provider_hash = { "resource": "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"+
                                   "<tns:provider xmlns:tns=\"http://einfracentral.eu\">" +
                                   "<tns:active>true</tns:active>" +
                                   "</tns:provider>",
                     "resourceType": "provider" }
    error_provider_message = double(body: provider_hash.to_json)
    allow(client).to receive(:subscribe).with("/topic/dummy_topic.>",
                                              { "ack": "client-individual",
                                                "activemq.subscriptionName": "mpSubscription" })
                                                .and_yield(error_provider_message)

    provider_instance = instance_double(Provider::PcCreateOrUpdate)
    allow(Provider::PcCreateOrUpdate).to receive(:new).with(parser.parse(provider_hash[:resource])["provider"])
      .and_return(provider_instance)

    allow(provider_instance).to receive(:call).and_raise(StandardError)
    subscriber = mock_subscriber
    expect(client).to receive(:unreceive).with(error_provider_message)
    expect {
      subscriber.run
    }.to raise_error(SystemExit)
  end


  it "should receive error if connection fail" do
    stub_good_message

    allow(client).to receive(:open?).and_return(false)
    subscriber = mock_subscriber

    expect {
      subscriber.run
    }.to raise_error(Jms::Subscriber::ConnectionError, "Connection failed!!")
  end

  it "should receive error if queue send error frame" do
    stub_good_message

    allow(client).to receive(:open?).and_return(true)
    allow(client).to receive(:connection_frame).and_return(double(command: Stomp::CMD_ERROR, body: "Error"))
    subscriber = mock_subscriber

    expect {
      subscriber.run
    }.to raise_error(Jms::Subscriber::ConnectionError, "Connect error: Error")
  end

  it "should receive error if message is invalid" do
    service_hash = { "some_happy_key": "some_happy_value" }
    error_service_message = double(body: service_hash.to_json)
    allow(client).to receive(:subscribe).with("/topic/dummy_topic.>",
                                              { "ack": "client-individual",
                                                "activemq.subscriptionName": "mpSubscription" })
                                                .and_yield(error_service_message)

    subscriber = mock_subscriber
    expect(client).to receive(:unreceive).with(error_service_message)
    expect {
      subscriber.run
    }.to raise_error(SystemExit)
  end

  private
    def config_hash
      {
        hosts: [
          {
            login: "dummy_login",
            passcode: "dummy_pass",
            host:  "dummy_host",
            port: 61613,
            ssl: false
          }
        ],
        connect_headers: {
          "client-id": "MPClientTest",
          "heart-beat": "0,20000",
          "accept-version": "1.2",
          "host": "localhost"
        }
      }
    end
end
