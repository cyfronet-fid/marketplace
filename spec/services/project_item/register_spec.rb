# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Register do
  let(:project_item) { create(:project_item, offer: create(:offer)) }
  let(:issue) { double("Issue", id: 1) }


  before(:each) {
    jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
    jira_class_stub = class_double(Jira::Client).
        as_stubbed_const(transfer_nested_constants: true)

    allow(jira_class_stub).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
    allow(jira_client).to receive(:create_service_issue).and_return(issue)
  }

  it "creates new jira issue" do
    jira_client = Jira::Client.new

    expect(jira_client).to receive(:create_service_issue).with(project_item)

    described_class.new(project_item).call
    expect(project_item.project_item_changes.last).to be_registered
  end

  it "creates new project_item change" do
    described_class.new(project_item).call
    expect(project_item.project_item_changes.last).to be_registered
  end

  it "changes project_item status into registered on success" do
    described_class.new(project_item).call

    expect(project_item).to be_registered
  end

  it "sent email to project_item owner" do
    # project_item change email is sent only when there is more than 1 change
    project_item.new_change(status: :created, message: "ProjectItem created")

    expect { described_class.new(project_item).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
