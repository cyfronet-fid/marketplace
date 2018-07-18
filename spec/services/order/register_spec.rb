# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Register do
  let(:order) { create(:order, service: create(:service)) }
  let(:issue) { double("Issue", id: 1) }


  before(:each) {
    jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
    jira_class_stub = class_double(Jira::Client).
        as_stubbed_const(transfer_nested_constants: true)

    allow(jira_class_stub).to receive(:new).and_return(jira_client)
    allow(issue).to receive(:save).and_return(issue)
    allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
    allow(jira_client).to receive_message_chain(:Issue, :build) { issue }
  }

  it "creates new jira issue" do
    jira_client = Jira::Client.new

    expect(issue).to receive(:save).with(fields: {
        summary: "Requested realization of #{order.service.title}",
        project: { key: jira_client.jira_project_key },
        issuetype: { id: jira_client.jira_issue_type_id }
    })

    described_class.new(order).call
    expect(order.order_changes.last).to be_registered
  end

  it "creates new order change" do
    described_class.new(order).call
    expect(order.order_changes.last).to be_registered
  end

  it "changes order status into registered on success" do
    described_class.new(order).call

    expect(order).to be_registered
  end

  it "sent email to order owner" do
    # order change email is sent only when there is more than 1 change
    order.new_change(status: :created, message: "Order created")

    expect { described_class.new(order).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
