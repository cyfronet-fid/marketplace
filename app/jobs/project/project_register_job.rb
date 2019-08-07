# frozen_string_literal: true

class Project::ProjectRegisterJob < ApplicationJob
  queue_as :orders

  rescue_from(Jira::Client::JIRAIssueCreateError) do |exception|
    # TODO: we need to define what to do when question registration in e.g.
    #       JIRA fails. Maybe we should report this problem to Sentry and
    #       do some manual intervantion?
    raise exception
  end

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
    raise exception
  end

  def perform(project)
    Project::Register.new(project).call
  end
end
