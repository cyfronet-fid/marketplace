# frozen_string_literal: true

class ProjectItem::ReadyJob < ApplicationJob
  queue_as :project_items

  def perform(project_item)
    ProjectItem::Ready.new(project_item).call
  end
end
