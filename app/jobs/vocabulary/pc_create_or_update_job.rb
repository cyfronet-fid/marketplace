# frozen_string_literal: true

class Vocabulary::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(vocabulary)
    Vocabulary::PcCreateOrUpdate.new(vocabulary).call
  end
end
