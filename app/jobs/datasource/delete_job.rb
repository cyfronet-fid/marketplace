# frozen_string_literal: true

class Datasource::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(provider_id)
    Datasource::Delete.new(provider_id).call
  end
end
