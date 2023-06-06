# frozen_string_literal: true

require "rails_helper"

describe Jms::Publisher, backend: true do
  let(:logger) { double }
  let(:client) { double(Stomp::Client) }
  let(:client_config) do
    {
      hosts: [{ login: "user", passcode: "password", host: "example.com", port: 61_613, ssl: false }],
      connect_timeout: 5,
      max_reconnect_attempts: 5,
      connect_headers: {
        "accept-version": "1.2",
        host: "localhost",
        "heart-beat": "0,20000"
      }
    }
  end
  let(:message) { { foo: "bar" } }
  let(:message_headers) { { persistent: true, suppress_content_length: true, "content-type": "application/json" } }

  it "works correctly" do
    expect(Stomp::Client).to receive(:new).with(client_config).and_return(client)
    expect_any_instance_of(Jms::Publisher).to receive(:verify_connection!)

    publisher = Jms::Publisher.new("foo", "user", "password", "example.com", false, logger)

    expect(logger).to receive(:debug).with("Publishing to foo, message {:foo=>\"bar\"}")
    expect(client).to receive(:publish).with("/topic/foo", message, message_headers)
    publisher.publish(message)

    expect(client).to receive(:close)
    publisher.close
  end

  context "#publish" do
    it "propagates packaged errors" do
      allow(Stomp::Client).to receive(:new).with(client_config).and_return(client)
      allow_any_instance_of(Jms::Publisher).to receive(:verify_connection!)

      publisher = Jms::Publisher.new("foo", "user", "password", "example.com", false, logger)

      expect(logger).to receive(:debug).with("Publishing to foo, message {:foo=>\"bar\"}")
      expect(client).to receive(:publish).with("/topic/foo", message, message_headers).and_raise(RuntimeError)

      expect { publisher.publish(message) }.to raise_error(Jms::Publisher::PublishError) do |e|
        expect(e.cause).to be_a(RuntimeError)
      end
    end
  end

  context "#verify_connection!" do
    let(:cmd_error_connection_frame) { double(command: Stomp::CMD_ERROR, body: "baz") }

    it "doesn't raise if connect works" do
      expect(Stomp::Client).to receive(:new).with(client_config).and_return(client)
      expect(client).to receive(:open?).and_return(true)
      expect(client).to receive_message_chain(:connection_frame, :command).and_return(nil)

      Jms::Publisher.new("foo", "user", "password", "example.com", false, logger)
    end

    it "raises if client isn't open" do
      expect(Stomp::Client).to receive(:new).with(client_config).and_return(client)
      expect(client).to receive(:open?).and_return(false)

      expect { Jms::Publisher.new("foo", "user", "password", "example.com", false, logger) }.to raise_error(
        Jms::Publisher::ConnectionError,
        "Connection failed!!"
      )
    end

    it "raises if command error received on open" do
      expect(Stomp::Client).to receive(:new).with(client_config).and_return(client)
      expect(client).to receive(:open?).and_return(true)
      expect(client).to receive(:connection_frame).and_return(cmd_error_connection_frame).twice

      expect { Jms::Publisher.new("foo", "user", "password", "example.com", false, logger) }.to raise_error(
        Jms::Publisher::ConnectionError,
        "Connection error: baz"
      )
    end
  end
end
