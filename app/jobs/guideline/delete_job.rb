# frozen_string_literal: true

class Guideline::DeleteJob < ApplicationJob
  queue_as :pc_subscriber

  def perform(eid)
    guideline = Guideline.find_by(eid: eid)
    guideline&.destroy
  end
end
