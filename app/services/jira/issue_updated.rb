# frozen_string_literal: true

class Jira::IssueUpdated
  def initialize(project_item, changelog)
    @project_item = project_item
    @changelog = changelog || {}
    @jira_client = Jira::Client.new
  end

  def call
    @changelog
      .fetch("items", [])
      .each do |change|
        status_type = nil

        case change["field"]
        when "status"
          case change["to"].to_i
          when @jira_client.wf_rejected_id
            status_type = :rejected
          when @jira_client.wf_waiting_for_response_id
            status_type = :waiting_for_response
          when @jira_client.wf_todo_id
            status_type = :registered
          when @jira_client.wf_in_progress_id
            status_type = :in_progress
          when @jira_client.wf_ready_id
            status_type = :ready
          when @jira_client.wf_closed_id
            status_type = :closed
          when @jira_client.wf_approved_id
            status_type = :approved
          else
            Rails.logger.warn("Unknown issue status_type (#{change["to"]}")
          end

          @project_item.new_status(status: status_type.to_s, status_type: status_type) if status_type
        when "CP-VoucherID"
          @project_item.new_voucher_change(change["toString"])
        end
      end
  end
end
