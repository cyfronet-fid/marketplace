# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project::Archive do
  let(:project) { create(:project) }
  let(:issue) { double("Issue", id: 1) }
  let(:transition) { double("Transition") }

  context "(JIRA works without errors)" do
    before(:each) {
      wf_archived_id = 6

      jira_client = double("Jira::Client",
                           jira_project_key: "MP",
                           jira_issue_type_id: 5,
                           wf_archived_id: wf_archived_id)
      transition_archive = double("Transition", id: "2", name: "____ARCHIVED____",
                               to: double(id: wf_archived_id.to_s))
      jira_class_stub = class_double(Jira::Client).
          as_stubbed_const(transfer_nested_constants: true)

      allow(jira_class_stub).to receive(:new).and_return(jira_client)
      allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
      allow(issue).to receive_message_chain(:transitions, :all) { [ transition_archive] }
      allow(issue).to receive_message_chain(:transitions, :build) { transition }
      allow(transition). to receive(:save!).and_return(transition)
    }

    it "archive project" do
      described_class.new(project).call

      expect(project.status).to eq("archived")
    end
  end
end
