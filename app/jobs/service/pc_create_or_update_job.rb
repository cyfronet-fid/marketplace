# frozen_string_literal: true

class Service::PcCreateOrUpdateJob < ApplicationJob
  queue_as :jms

  rescue_from(Errno::ECONNREFUSED) do |exception|
    raise exception
  end

  def perform(infra_service, eic_base_url, is_active, modified_at)
    Service::PcCreateOrUpdate.new(infra_service,
                                  eic_base_url,
                                  is_active,
                                  modified_at).call
  end
end
