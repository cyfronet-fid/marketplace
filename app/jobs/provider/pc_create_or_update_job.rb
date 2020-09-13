# frozen_string_literal: true

class Provider::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider)
    Provider::PcCreateOrUpdate.new(provider)
  end
end
