# frozen_string_literal: true

class Service::PcCreateOrUpdateJob < ApplicationJob
  queue_as :jms

  def perform(infra_service, eic_base_url, is_active)
    Service::PcCreateOrUpdate.new(infra_service,
                                          eic_base_url,
                                          is_active).call
  end
end
