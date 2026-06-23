# frozen_string_literal: true

require "rails_helper"
require "jms/subscriber"
require "stomp"

describe Jms::Subscriber, backend: true do
  let(:logger) { Logger.new(nil) }
  let(:message) { double(body: "{}") }
  let(:test_client) { double("Stomp::Client", open?: true, close: true) }
  let(:client) { double("Stomp::Client", open?: true, connection_frame: nil, ack: true, join: true) }
  let(:config) do
    {
      subscriptions: [
        {
          login: "dummy_login",
          password: "dummy_pass",
          host: "dummy_host",
          topic: "dummy_topic",
          client_name: "MPClientTest",
          eosc_registry_base_url: "localhost",
          ssl_enabled: false
        }
      ]
    }
  end

  before { allow_any_instance_of(Jms::Subscriber).to receive(:load_config).and_return(config) }

  it "raises if the connection test fails" do
    allow(Stomp::Client).to receive(:new).and_return(double("Stomp::Client", open?: false))

    expect { described_class.new(logger: logger).run }.to raise_error(
      Jms::Subscriber::ConnectionError,
      "Cannot connect to dummy_host:61613: Test connection failed for dummy_host:61613"
    )
  end

  it "subscribes, processes, and acknowledges a message" do
    allow(Stomp::Client).to receive(:new).and_return(test_client, client)
    allow(client).to receive(:subscribe).with(
      "/topic/dummy_topic.>",
      { ack: "client-individual", "activemq.subscriptionName": "mpSubscription" }
    ).and_yield(message)

    expect(Jms::ManageMessage).to receive(:call).with(message, "localhost", logger, nil)
    expect(client).to receive(:ack).with(message)

    described_class.new(logger: logger).run
  end

  it "subscribes to each comma-separated topic" do
    config[:subscriptions].first[:topic] = [
      "*.organisation.*",
      "*.service.*",
      " *.catalogue.*",
      "*.datasource.*",
      "*.deployable_application.*",
      "*.interoperability_record.*"
    ].join(",")

    allow(Stomp::Client).to receive(:new).and_return(test_client, client)
    allow(client).to receive(:subscribe)

    %w[
      *.organisation.*
      *.service.*
      *.catalogue.*
      *.datasource.*
      *.deployable_application.*
      *.interoperability_record.*
    ].each do |topic|
      expect(client).to receive(:subscribe).with(
        "/topic/#{topic}.>",
        { ack: "client-individual", "activemq.subscriptionName": "mpSubscription" }
      )
    end

    described_class.new(logger: logger).run
  end

  it "unreceives a message when processing fails" do
    allow(Stomp::Client).to receive(:new).and_return(test_client, client)
    allow(client).to receive(:subscribe).and_yield(message)
    allow(Jms::ManageMessage).to receive(:call).and_raise(StandardError, "boom")

    expect(client).to receive(:unreceive).with(message)

    described_class.new(logger: logger).run
  end
end
