# frozen_string_literal: true

class ProjectItem::ReadyJob < ApplicationJob
  queue_as :orders

  def perform(project_item, message = nil)
    ProjectItem::Ready.new(project_item, message).call
  end
end
