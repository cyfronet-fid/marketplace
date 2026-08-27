# frozen_string_literal: true

module Ams
  class Subscribe
    include Callable

    def initialize(subscription_name)
      @subscription_name = subscription_name
      @ack_ids = []
    end

    def call
      response = client.pull(subscription_name)

      messages = get_messages(response)
      ack_ids = messages.filter_map { |message| process(message) }

      client.acknowledge(subscription_name, ack_ids: ack_ids)
    end

    private

    attr_reader :subscription_name

    def get_messages(response)
      JSON.parse(response.body)["receivedMessages"] || []
    end

    def process(message)
      ack_id = message["ackId"]

      decoded_message = Ams::DecodeMessage.call(message)
      result = Ams::ProcessMessage.call(subscription_name, message: decoded_message)

      ack_id if result
    end

    def client
      @client ||= Ams::Client.new
    end
  end
end
