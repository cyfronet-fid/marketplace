# frozen_string_literal: true

require "rails_helper"
require "jira/project_migrator"

describe Jira::Setup do
  let(:jira_project_key) { "MP" }
  let(:jira_client) { double("Jira::Client", jira_project_key: jira_project_key, jira_config: { username: "admin" },
                             custom_fields: { "Epic Link": "EpicLinkCustomFieldID" }) }
  let(:project_migrator) { Jira::ProjectMigrator.new(jira_client) }
  let(:project) { create(:project, issue_status: :jira_require_migration, issue_key: nil, issue_id: nil) }
  let(:project_issue) { double("Issue", id: 1, key: "MP-1") }

  it "call do nothing if all projects have issues" do
    original_stdout = $stdout
    $stdout = StringIO.new
    expect { project_migrator.call }.to output("There are not projects requiring migration\n").to_stdout
    $stdout = original_stdout
  end

  it "call should create issues for project requiring migration" do
    # Disable stdout, to make it easier when running in terminal
    original_stdout = $stdout
    $stdout = StringIO.new

    project_with_active_issue = create(:project)

    expect(jira_client).to receive(:create_project_issue).with(project).and_return(project_issue)
    expect(jira_client).to_not receive(:create_project_issue).with(project_with_active_issue)

    project_migrator.call
    $stdout = original_stdout
  end

  it "call should create update Epic Link for project's project_items" do
    # Disable stdout, to make it easier when running in terminal
    original_stdout = $stdout
    $stdout = StringIO.new

    pi = create(:project_item, project: project, issue_status: :jira_active, issue_id: 1)
    pi_issue = double("Issue", id: 2, key: "MP-2")

    expect(pi_issue).to receive(:save).with(fields: { "EpicLinkCustomFieldID" => project_issue.key })

    expect(jira_client).to receive(:create_project_issue).with(project).and_return(project_issue)

    expect(jira_client).to receive_message_chain("Issue.find").with(pi.issue_id).and_return(pi_issue)

    project_migrator.call
    $stdout = original_stdout
  end
end
