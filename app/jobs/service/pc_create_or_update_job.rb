# frozen_string_literal: true

class Service::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(infra_service, status, modified_at)
    Service::PcCreateOrUpdate.new(infra_service, status, modified_at).call
  end
end
