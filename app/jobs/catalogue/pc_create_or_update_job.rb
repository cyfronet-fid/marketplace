# frozen_string_literal: true

class Catalogue::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(catalogue, is_active, modified_at)
    Catalogue::PcCreateOrUpdate.new(catalogue, is_active, modified_at).call
  end
end
