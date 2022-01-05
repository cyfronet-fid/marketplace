# frozen_string_literal: true

class Project::Register
  def initialize(project)
    @project = project
  end

  def call
    register_in_jira! unless @project.jira_active?
  end

  private

  def register_in_jira!
    client = Jira::Client.new
    @project.save!

    begin
      issue = client.create_project_issue(@project)
      @project.update!(issue_id: issue.id, issue_key: issue.key, issue_status: :jira_active)
      @project.save!
      true
    rescue Jira::Client::JIRAIssueCreateError => e
      @project.jira_errored!
      raise e
    end
  end
end
