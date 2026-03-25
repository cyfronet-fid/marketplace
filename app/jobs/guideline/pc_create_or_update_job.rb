# frozen_string_literal: true

class Guideline::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  rescue_from(Errno::ECONNREFUSED) { |exception| raise exception }

  def perform(guideline_data, status, modified_at)
    Guideline::PcCreateOrUpdate.new(guideline_data, status, modified_at).call
  end
end
