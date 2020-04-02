# frozen_string_literal: true

class Matomo::SendRequestJob < ApplicationJob
  queue_as :matomo

  def perform(project_item, action, value = nil)
    Matomo::CreateEvent.new(project_item, action, value).call
  end
end
