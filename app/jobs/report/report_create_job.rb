# frozen_string_literal: true

class Report::ReportCreateJob < ApplicationJob
  queue_as :reports

  rescue_from(Report::Client::XGUSIssueCreateError) { |exception| raise exception }

  rescue_from(StandardError) do |exception|
    # This is general error, which should not occur, but should be
    # caught just in case
    raise exception
  end

  def perform(report)
    Report::Register.new(report).call
  end
end
