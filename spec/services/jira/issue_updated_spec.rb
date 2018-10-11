# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::IssueUpdated do
  include JiraHelper

  before { stub_jira }

  let(:order) { create(:order) }

  it "creates new changelog entry" do
    described_class.new(order, changelog(to: jira_client.wf_in_progress_id)).call

    expect(order.order_changes.last).to be_in_progress
  end

  it "set dedicated changelog message when service become ready" do
    described_class.new(order, changelog(to: jira_client.wf_done_id)).call
    last_change = order.order_changes.last

    expect(last_change).to be_ready
    expect(last_change.message).to include "ready to be used"
  end

  def changelog(to:)
    { "items" => [
      { "field" => "status", "to" => to }
    ] }
  end
end
