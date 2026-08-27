# frozen_string_literal: true

class Ams::SubscribeJob < ApplicationJob
  queue_as :ams_subscriber

  def perform(subscription_name)
    Ams::Subscribe.call(subscription_name)
  end
end
