# frozen_string_literal: true

class Project::JiraUpdateJob < ApplicationJob
  queue_as :orders

  def perform(project)
    Project::JiraUpdate.new(project).call
  end
end
