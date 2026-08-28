# frozen_string_literal: true

module Ams
  class Subscribe
    include Callable

    def initialize(subscription_name)
      @subscription_name = subscription_name
    end

    def call
      response = client.pull(subscription_name)
      raise "AMS pull failed for #{subscription_name}: #{response.status}" unless response.success?

      messages = get_messages(response)
      ack_ids = messages.filter_map { |message| process(message) }
      return if ack_ids.blank?

      ack_response = client.acknowledge(subscription_name, ack_ids: ack_ids)
      raise "AMS acknowledge failed for #{subscription_name}: #{ack_response.status}" unless ack_response.success?
    end

    private

    attr_reader :subscription_name

    def get_messages(response)
      response.body["receivedMessages"] || []
    end

    def process(message)
      ack_id = message["ackId"]

      decoded_message = Ams::DecodeMessage.call(message["message"])
      result = Ams::ProcessMessage.call(subscription_name, message: decoded_message)

      ack_id if result
    end

    def client
      @client ||= Ams::Client.new
    end
  end
end
