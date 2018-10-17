# frozen_string_literal: true

class Jira::IssueUpdated
  def initialize(project_item, changelog)
    @project_item = project_item
    @changelog = changelog || {}
    @jira_client = Jira::Client.new
  end

  def call
    @changelog.fetch("items", []).each do |change|
      status = nil
      message = "Status changed"

      if change["field"] == "status"
        case change["to"].to_i
        when @jira_client.wf_todo_id
          status = :registered
        when @jira_client.wf_in_progress_id
          status = :in_progress
        when @jira_client.wf_done_id
          status = :ready
          message = "Service is ready to be used"
        else
          Rails.logger.warn("Unknown issue status (#{change["to"]}")
        end

        if status
          @project_item.new_change(status: status, message: message)
          ProjectItemMailer.changed(@project_item).deliver_later
        end
      end
    end
  end
end
