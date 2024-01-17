# frozen_string_literal: true

class Provider::PcCreateOrUpdateJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider, status, modified_at)
    Provider::PcCreateOrUpdate.call(provider, status, modified_at)
  end
end
