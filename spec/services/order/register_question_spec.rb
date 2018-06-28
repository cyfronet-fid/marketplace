# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::RegisterQuestion do
  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:order) { create(:order, user: user, service: service, issue_id: 1) }
  let(:question) { "Question message" }
  let(:comment) { double("Comment") }

  # Stub JIRA client
  before(:each) do
    jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
    jira_class_stub = class_double(Jira::Client).
        as_stubbed_const(transfer_nested_constants: true)

    issue = double("Issue", id: 1)
    comments = double("Comments", build: comment)
    allow(issue).to receive(:save).and_return(issue)
    allow(issue).to receive(:comments).and_return(comments)
    allow(jira_class_stub).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
  end

  it "Should create jira comment from question" do
    expect(comment).to receive(:save).with(body: question).and_return(comment)
    service = Order::RegisterQuestion.new(order, question)
    service.call
  end

  it "Should raise JIRACommentCreateError if comment was not created" do
    expect(comment).to receive(:save).with(body: question).and_return(nil)
    service = Order::RegisterQuestion.new(order, question)

    expect { service.call }.to raise_error(Order::RegisterQuestion::JIRACommentCreateError)
  end
end
