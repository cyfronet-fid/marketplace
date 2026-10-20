# frozen_string_literal: true

class Service::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(service_id)
    Service::PcDelete.new(service_id).call
  end
end
