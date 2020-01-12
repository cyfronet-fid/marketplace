#  frozen_string_literal: true

class Report::Create
  def initialize(report)
    @report = report
  end

  def call
    Report::ReportCreateJob.perform_later(@report)
  end
end
