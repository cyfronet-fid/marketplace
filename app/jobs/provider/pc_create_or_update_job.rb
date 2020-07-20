# frozen_string_literal: true

class Provider::PcCreateOrUpdateJob < ApplicationJob
  queue_as :jms

  def perform(provider)
    Provider::PcCreateOrUpdate.new(provider)
  end
end
