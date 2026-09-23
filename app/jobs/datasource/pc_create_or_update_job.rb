# frozen_string_literal: true

class Datasource::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(datasource, status, modified_at)
    Datasource::PcCreateOrUpdate.new(datasource, status, modified_at).call
  end
end
