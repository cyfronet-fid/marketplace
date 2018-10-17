# frozen_string_literal: true

class ProjectItem::RegisterJob < ApplicationJob
  queue_as :project_items

  rescue_from(ProjectItem::Register::JIRAIssueCreateError) do |exception|
    # TODO: we need to define what to do when question registration in e.g.
    #       JIRA fails. Maybe we should report this problem to Sentry and
    #       do some manual intervantion?
  end

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
  end

  def perform(project_item)
    ProjectItem::Register.new(project_item).call
  end
end
