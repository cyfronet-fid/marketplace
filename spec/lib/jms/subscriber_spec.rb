# frozen_string_literal: true

require "rails_helper"
require "jms/subscriber"
require "stomp"

describe Jms::Subscriber, backend: true do
  let(:eosc_registry_base) { "localhost" }
  let(:logger) { Logger.new($stdout) }
  let(:parser) { JSON }
  let(:client) { double("Stomp::Client", config_hash) }
  let(:client_stub) { class_double(Stomp::Client).as_stubbed_const(transfer_nested_constants: true) }
  let(:service_resource) { create(:jms_json_service) }
  let(:provider_resource) { create(:jms_json_provider) }
  let(:json_service) { double(body: service_resource.to_json) }
  let(:json_provider) { double(body: provider_resource.to_json) }
  let(:connection) do
    double(
      "connection",
      :autoflush= => true,
      :login => "dummy_login",
      :passcode => "dummy_pass",
      :port => 12_345,
      :host => "dummy_host",
      :ssl => "false"
    )
  end

  let(:manage_message_service) { instance_double(Jms::ManageMessage) }

  def mock_subscriber
    allow_any_instance_of(Jms::Subscriber).to receive(:conf_hash).with(
      "dummy_login",
      "dummy_pass",
      "dummy_host",
      "MPClientTest",
      false
    ).and_return(config_hash)

    allow(client_stub).to receive(:new).and_return(client)
    Jms::Subscriber.new(
      "dummy_topic",
      "dummy_login",
      "dummy_pass",
      "dummy_host",
      "MPClientTest",
      "localhost",
      false,
      nil,
      client: client_stub,
      logger: logger
    )
  end

  def stub_good_message
    allow(client).to receive(:subscribe).with(
      "/topic/dummy_topic.>",
      { ack: "client-individual", "activemq.subscriptionName": "mpSubscription" }
    ).and_yield(json_service)

    allow(client).to receive(:ack).with(json_service)
    allow(Jms::ManageMessage).to receive(:new).with(json_service, eosc_registry_base, logger, nil).and_return(
      manage_message_service
    )
    allow(manage_message_service).to receive(:call).and_return(true)
  end

  it "should receive error if connection fail" do
    original_stdout = $stdout
    $stdout = StringIO.new

    stub_good_message

    allow(client).to receive(:open?).and_return(false)
    subscriber = mock_subscriber

    expect { subscriber.run }.to raise_error(Jms::Subscriber::ConnectionError, "Connection failed!!")
    $stdout = original_stdout
  end

  it "should receive error if queue send error frame" do
    original_stdout = $stdout
    $stdout = StringIO.new
    stub_good_message

    allow(client).to receive(:open?).and_return(true)
    allow(client).to receive(:connection_frame).and_return(double(command: Stomp::CMD_ERROR, body: "Error"))
    subscriber = mock_subscriber

    expect { subscriber.run }.to raise_error(Jms::Subscriber::ConnectionError, "Connection error: Error")
    $stdout = original_stdout
  end

  it "should receive error if queue send error frame" do
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    allow(client).to receive(:subscribe).with(
      "/topic/dummy_topic.>",
      { ack: "client-individual", "activemq.subscriptionName": "mpSubscription" }
    ).and_yield({})

    allow(Jms::ManageMessage).to receive(:new).with({}, eosc_registry_base, logger, nil).and_return(
      manage_message_service
    )
    allow(manage_message_service).to receive(:call).and_raise(StandardError)
    subscriber = mock_subscriber

    expect(client).to receive(:unreceive).with({})
    expect { subscriber.run }.to raise_error(SystemExit)
    $stdout = original_stdout
    $stderr = original_stderr
  end

  private

  def config_hash
    {
      hosts: [{ login: "dummy_login", passcode: "dummy_pass", host: "dummy_host", port: 61_613, ssl: false }],
      connect_headers: {
        "client-id": "MPClientTest",
        "heart-beat": "0,20000",
        "accept-version": "1.2",
        host: "localhost"
      }
    }
  end
end
