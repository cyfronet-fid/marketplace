# frozen_string_literal: true

class Datasource::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(datasource, is_active, eosc_registry_base_url, token, modified_at)
    Datasource::PcCreateOrUpdate.new(datasource, eosc_registry_base_url, is_active, token, modified_at).call
  end
end
