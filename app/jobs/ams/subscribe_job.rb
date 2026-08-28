# frozen_string_literal: true

class Ams::SubscribeJob < ApplicationJob
  queue_as :ams_subscriber
  sidekiq_options retry: 3

  def perform(subscription_name)
    Ams::Subscribe.call(subscription_name)
  end
end
