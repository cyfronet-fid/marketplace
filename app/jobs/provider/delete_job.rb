# frozen_string_literal: true

class Provider::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider_id)
    Provider::PcDelete.new(provider_id).call
  end
end
