# frozen_string_literal: true

require "colorize"

module Xgus
  class Checker
    def check
      report = Report.new(author: "Automatic tester",
                          email: "marketplace@eosc-portal.eu",
                          text: "Integration test check")
      client = Report::Client.new
      response = client.create!(report)
      if response.success?
        Rails.logger.debug "SUCCESS: ".green << "Ticket created" << "\n"
      else
        Rails.logger.debug "FAIL: ".red << "Cannot establish connection" << "\n"
        Rails.logger.debug response.http
      end
    end
  end
end
