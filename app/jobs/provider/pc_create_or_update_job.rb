# frozen_string_literal: true

class Provider::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider, modified_at)
    Provider::PcCreateOrUpdate.new(provider, modified_at).call
  end
end
