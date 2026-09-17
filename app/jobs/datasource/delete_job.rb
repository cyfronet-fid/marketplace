# frozen_string_literal: true

class Datasource::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(service_id)
    Datasource::PcDelete.new(service_id).call
  end
end
