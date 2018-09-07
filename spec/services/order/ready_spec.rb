# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Ready do
  let(:order) { create(:order) }
  let(:issue) { double("Issue", id: 1) }
  let(:transition) { double("Transition") }


  before(:each) {
    jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
    transition_start = double("Transition", id: "1", name: "Start Progress")
    transition_done = double("Transition", id: "2", name: "Done")
    jira_class_stub = class_double(Jira::Client).
        as_stubbed_const(transfer_nested_constants: true)


    allow(jira_class_stub).to receive(:new).and_return(jira_client)
    allow(issue).to receive(:save).and_return(issue)
    allow(issue).to receive_message_chain(:transitions, :find) { issue }
    allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
    allow(jira_client).to receive_message_chain(:Issue, :build) { issue }
    allow(issue).to receive_message_chain(:transitions, :all) { [transition_start, transition_done] }
    allow(issue).to receive_message_chain(:transitions, :build) { transition }
    allow(transition). to receive(:save!).and_return(transition)
  }

  it "creates new order change" do
    described_class.new(order).call

    expect(order.order_changes.last).to be_ready
  end

  it "changes order status into ready on success" do
    described_class.new(order).call

    expect(order).to be_ready
  end

  it "creates new jira issue and do the transition" do
    jira_client = Jira::Client.new

    expect(issue).to receive(:save).with(fields: {
        summary: "Add open service #{order.service.title}",
        project: { key: jira_client.jira_project_key },
        issuetype: { id: jira_client.jira_issue_type_id }
    })

    expect(transition).to receive(:save!).with("transition" => { "id" => "2" })

    described_class.new(order).call
    expect(order).to be_ready

  end

  it "sent email to order owner" do
    # order change email is sent only when there is more than 1 change
    order.new_change(status: :ready, message: "Order is ready")

    expect { described_class.new(order).call }.
      to change { ActionMailer::Base.deliveries.count }.by(2)
    expect(ActionMailer::Base.deliveries[-2].subject).to start_with("[Order #")
    expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
  end
end
