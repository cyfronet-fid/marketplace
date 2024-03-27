#  frozen_string_literal: true

class Report::Register
  def initialize(report)
    @report = report
  end

  def call
    client = Report::Client.new
    client.create!(@report)
    true
  end
end
