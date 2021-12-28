# frozen_string_literal: true

class Project::Archive
  class JIRATransitionSaveError < StandardError
    def initialize(project, msg = "")
      super(msg)
      @project = project
    end
  end

  def initialize(project)
    @project = project
  end

  def call
    ready_in_jira! && archive!
  end

  def ready_in_jira!
    client = Jira::Client.new
    issue = client.Issue.find(@project.issue_key)
    trs = issue.transitions.all.select { |tr| tr.to.id.to_i == client.wf_archived_id }

    if trs.empty?
      @project.jira_errored!
      raise JIRATransitionSaveError, @project
    else
      transition = issue.transitions.build
      transition.save!("transition" => { "id" => trs.first.id })
      @project.update(issue_id: issue.id, issue_status: :jira_active)
    end
  end

  def archive!
    @project.update(status: :archived)
  end
end
