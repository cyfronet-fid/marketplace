# frozen_string_literal: true

class Jira::IssueUpdated
  def initialize(order, changelog)
    @order = order
    @changelog = changelog
    @jira_client = Jira::Client.new
  end

  def call
    @changelog.fetch("items", []).each do |change|
      status = nil
      message = "Order status changed"

      if change["field"] == "status"
        case change["to"].to_i
        when @jira_client.wf_todo_id
          status = :registered
        when @jira_client.wf_in_progress_id
          status = :in_progress
        when @jira_client.wf_done_id
          status = :ready
          message = "Ordered service is ready to be used"
        else
          Rails.logger.warn("Unknown issue status (#{change["to"]}")
        end

        if status
          @order.new_change(status: status, message: message)
          OrderMailer.changed(@order).deliver_later
        end
      end
    end
  end
end
