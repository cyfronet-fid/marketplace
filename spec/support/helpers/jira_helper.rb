# frozen_string_literal: true

module JiraHelper
  def stub_jira
    jira_client = double("Jira::Client",
                         jira_project_key: "MP",
                         jira_issue_type_id: 5,
                         webhook_secret: "secret",
                         wf_todo_id: 5,
                         wf_in_progress_id: 6,
                         wf_done_id: 7)
    jira_class_stub = class_double(Jira::Client).
                      as_stubbed_const(transfer_nested_constants: true)
    allow(jira_class_stub).to receive(:new).and_return(jira_client)

    jira_client
  end

  def jira_client
    @jira_client ||= Jira::Client.new
  end
end
