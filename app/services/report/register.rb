#  frozen_string_literal: true

class Report::Register
  def initialize(report)
    @report = report
  end

  def call
    client = Report::Client.new
    client.create_xgus_issue(@report)
    true
    rescue Report::Client::XGUSIssueCreateError => e
      raise e
  end
end
