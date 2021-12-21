# frozen_string_literal: true

class Service::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(infra_service, eosc_registry_base_url, is_active, modified_at, token = nil)
    Service::PcCreateOrUpdate.new(infra_service, eosc_registry_base_url, is_active, modified_at, token).call
  end
end
