# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::IssueUpdated, backend: true do
  include JiraHelper

  before { stub_jira }

  let(:project_item) { create(:project_item) }

  it "creates new status" do
    described_class.new(project_item, changelog(to: jira_client.wf_in_progress_id)).call

    expect(project_item.statuses.last).to be_in_progress
  end

  it "set dedicated changelog message when service become ready" do
    described_class.new(project_item, changelog(to: jira_client.wf_ready_id)).call
    last_status = project_item.statuses.last

    expect(last_status).to be_ready
  end

  it "uses service activate message when service become closed" do
    service = create(:service)
    offer = create(:offer, service: service)
    project_item = create(:project_item, offer: offer)

    described_class.new(project_item, changelog(to: jira_client.wf_closed_id)).call
    last_status = project_item.statuses.last

    expect(last_status).to be_closed
  end

  it "set dedicated changelog message when service become approved" do
    described_class.new(project_item, changelog(to: jira_client.wf_approved_id)).call
    last_status = project_item.statuses.last

    expect(last_status).to be_approved
  end

  it "set dedicated changelog message when service become ready" do
    described_class.new(project_item, changelog(to: jira_client.wf_ready_id)).call
    last_status = project_item.statuses.last

    expect(last_status).to be_ready
  end

  context "EGI Applications on Demand" do
    it "notify if accepted" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service)
      project_item = create(:project_item, offer: offer)

      expect { described_class.new(project_item, changelog(to: jira_client.wf_ready_id)).call }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("EGI Applications on Demand service approved")
    end

    it "notify if voucher accepted" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service, voucherable: true)
      project_item = create(:project_item, offer: offer, voucher_id: "123456")

      expect { described_class.new(project_item, changelog(to: jira_client.wf_ready_id)).call }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("Elastic Cloud Compute Cluster (EC3) service with voucher approved")
    end

    it "notify if voucher rejected" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service, voucherable: true)
      project_item = create(:project_item, offer: offer, voucher_id: "123456")

      expect { described_class.new(project_item, changelog(to: jira_client.wf_rejected_id)).call }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
      mail = ActionMailer::Base.deliveries.last

      expect(mail.subject).to eq("Elastic Cloud Compute Cluster (EC3) service with voucher rejected")
    end

    it "updates user_secrets if voucher requested and granted" do
      platform_aod = create(:platform, name: "EGI Applications on Demand")
      service = create(:service, platforms: [platform_aod])
      offer = create(:offer, service: service, voucherable: true)
      project_item = create(:project_item, offer: offer, request_voucher: true)

      described_class.new(project_item, changelog(field: "CP-VoucherID", to_string: "123456")).call

      project_item.reload

      expect(project_item.user_secrets).to include("voucher_id" => "123456")
    end
  end

  def changelog(field: "status", to: nil, to_string: nil)
    { "items" => [{ "field" => field, "to" => to, "toString" => to_string }] }
  end
end
