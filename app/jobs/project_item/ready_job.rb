# frozen_string_literal: true

class ProjectItem::ReadyJob < ApplicationJob
  queue_as :orders

  def perform(project_item)
    ProjectItem::Ready.new(project_item).call
  end
end
