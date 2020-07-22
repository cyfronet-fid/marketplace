# frozen_string_literal: true

class Service::DeleteJob < ApplicationJob
  queue_as :jms

  def perform(service_id)
    Service::Delete.new(service_id).call
  end
end
