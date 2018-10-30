# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::IssueUpdated do
  include JiraHelper

  before { stub_jira }

  let(:project_item) { create(:project_item) }

  it "creates new changelog entry" do
    described_class.new(project_item, changelog(to: jira_client.wf_in_progress_id)).call

    expect(project_item.project_item_changes.last).to be_in_progress
  end

  it "set dedicated changelog message when service become ready" do
    described_class.new(project_item, changelog(to: jira_client.wf_done_id)).call
    last_change = project_item.project_item_changes.last

    expect(last_change).to be_ready
    expect(last_change.message).to include "ready to be used"
  end

  it "uses service activate message when service become ready" do
    service = create(:service, activate_message: "Welcome!!!")
    offer = create(:offer, service: service)
    project_item = create(:project_item, offer: offer)

    described_class.new(project_item, changelog(to: jira_client.wf_done_id)).call
    last_change = project_item.project_item_changes.last

    expect(last_change).to be_ready
    expect(last_change.message).to eq("Welcome!!!")
  end

  def changelog(to:)
    { "items" => [
      { "field" => "status", "to" => to }
    ] }
  end
end
