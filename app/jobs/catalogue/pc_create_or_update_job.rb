# frozen_string_literal: true

class Catalogue::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(catalogue, status, modified_at)
    Catalogue::PcCreateOrUpdate.new(catalogue, status, modified_at).call
  end
end
