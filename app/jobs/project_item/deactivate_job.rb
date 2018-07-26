
# frozen_string_literal: true

class ProjectItem::DeactivateJob < ApplicationJob
  queue_as :project_items

  def perform(project_item)
    ProjectItem::Deactivate.new(project_item).call
  end
end
