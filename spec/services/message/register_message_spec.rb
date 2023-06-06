# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message::RegisterMessage, backend: true do
  include JiraHelper

  let(:project_item) { create(:project_item, issue_id: 1) }
  let(:message) { create(:message, messageable: project_item, message: "Message message") }
  let(:comment) { double("Comment", id: 123) }

  # Stub JIRA client
  before(:each) do
    jira_client = stub_jira

    issue = double("Issue", id: 1)
    comments = double("Comments", build: comment)
    allow(issue).to receive(:save).and_return(issue)
    allow(issue).to receive(:comments).and_return(comments)
    allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
  end

  it "creates jira comment from message" do
    expect(comment).to receive(:save).with(body: message.message).and_return(comment)

    described_class.new(message).call
  end

  it "sets jira internal comment id" do
    expect(comment).to receive(:save).with(body: message.message).and_return(comment)

    described_class.new(message).call
    message.reload

    expect(message.iid).to eq(123)
  end

  it "raises JIRACommentCreateError if comment was not created" do
    allow(comment).to receive(:save).and_return(nil)

    expect { described_class.new(message).call }.to raise_error(Message::RegisterMessage::JIRACommentCreateError)
  end
end
