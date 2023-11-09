# frozen_string_literal: true

class Datasource::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(datasource)
    Datasource::PcCreateOrUpdate.new(datasource).call
  end
end
