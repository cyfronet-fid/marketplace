# frozen_string_literal: true

class Provider::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider, is_active, modified_at)
    Provider::PcCreateOrUpdate.new(provider, is_active, modified_at).call
  end
end
