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

  context "EGI Applications on Demand" do
    it "notify if accepted" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service)
      project_item = create(:project_item, offer: offer)

      expect {
        described_class.new(project_item, changelog(to: jira_client.wf_done_id)).call
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("EGI Applications on Demand service approved")
    end

    it "notify if voucher accepted" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service, voucherable: true)
      project_item = create(:project_item, offer: offer, voucher_id: "123456")

      expect {
        described_class.new(project_item, changelog(to: jira_client.wf_done_id)).call
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("Elastic Cloud Compute Cluster (EC3) service with voucher approved")
    end

    it "notify if voucher rejected" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service, voucherable: true)
      project_item = create(:project_item, offer: offer, voucher_id: "123456")

      expect {
        described_class.new(project_item, changelog(to: jira_client.wf_rejected_id)).call
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("Elastic Cloud Compute Cluster (EC3) service with voucher rejected")
    end
  end

  def changelog(to:)
    { "items" => [
      { "field" => "status", "to" => to }
    ] }
  end
end
