# frozen_string_literal: true

class Jira::Client < JIRA::Client
  attr_reader :jira_config
  attr_reader :jira_project_key
  attr_reader :jira_issue_type_id
  attr_reader :webhook_secret
  attr_reader :wf_todo_id, :wf_in_progress_id, :wf_done_id, :wf_rejected_id, :wf_waiting_for_response_id

  def initialize
    # read required options and initialize jira client
    @jira_config = Mp::Application.config_for(:jira)
    @webhook_secret = @jira_config["webhook_secret"]

    options = {
        username: @jira_config["username"],
        password: @jira_config["password"],
        site: @jira_config["url"],
        context_path: @jira_config["context_path"],
        auth_type: :basic,
        use_ssl: (/^https\:\/\// =~ @jira_config["url"])
    }

    @jira_project_key = @jira_config["project"]
    @jira_issue_type_id = @jira_config["issue_type_id"]

    @wf_todo_id = @jira_config["workflow"]["todo"]
    @wf_in_progress_id = @jira_config["workflow"]["in_progress"]
    @wf_done_id = @jira_config["workflow"]["done"]
    @wf_rejected_id = @jira_config["workflow"]["rejected"]
    @wf_waiting_for_response_id = @jira_config["workflow"]["waiting_for_response"]

    super(options)
  end

  def mp_issue_type
    self.Issuetype.find(@jira_issue_type_id)
  end

  def mp_project
    self.Project.find(@jira_project_key)
  end
end
