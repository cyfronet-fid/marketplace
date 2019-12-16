# frozen_string_literal: true

class Report::ReportCreateJob < ApplicationJob
  queue_as :reports

  rescue_from(Report::Client::XGUSIssueCreateError) do |exception|
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

  def perform(report)
    Report::Register.new(Report.load(report)).call
  end
end
