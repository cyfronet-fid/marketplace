# frozen_string_literal: true

class Project::JiraUpdate
  def initialize(project)
    @project = project
  end

  def call
    client = Jira::Client.new
    client.update_project_issue(@project)
  end
end
