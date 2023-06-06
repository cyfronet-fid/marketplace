# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project::JiraUpdate, backend: true do
  let(:project) { create(:project) }
  let(:issue) { double("Issue", id: 1, key: "MP-1") }

  context "(JIRA works without errors)" do
    before(:each) do
      jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
      jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)

      allow(jira_class_stub).to receive(:new).and_return(jira_client)
      allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
      allow(jira_client).to receive(:update_project_issue).and_return(issue)
    end

    it "update jira issue" do
      jira_client = Jira::Client.new

      project.name = "New Name"
      expect(jira_client).to receive(:update_project_issue).with(project)

      described_class.new(project).call

      expect(project.name).to eq("New Name")
    end
  end

  context "(JIRA raises Errors)" do
    let!(:jira_client) do
      client = double("Jira::Client", jira_project_key: "MP")
      jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)
      allow(jira_class_stub).to receive(:new).and_return(client)
      client
    end

    it "sets jira error and raises exception on failed jira issue creation" do
      project = create(:project, issue_status: :jira_uninitialized, issue_key: "1234", issue_id: 1234)

      error = Jira::Client::JIRAProjectIssueUpdateError.new(project, "key" => "can not have value X")

      allow(jira_client).to receive(:update_project_issue).with(project).and_raise(error)

      expect { described_class.new(project).call }.to raise_error(error)
      expect(project.jira_errored?).to be_truthy
    end
  end
end
