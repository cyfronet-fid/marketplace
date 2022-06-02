# frozen_string_literal: true

class Vocabulary::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(vocabulary_id)
    Vocabulary::Delete.new(vocabulary_id).call
  end
end
