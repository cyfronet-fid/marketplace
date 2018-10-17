# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::RegisterQuestion do
  include JiraHelper

  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:project_item) { create(:project_item, user: user, service: service, issue_id: 1) }
  let(:question) { create(:project_item_change, project_item: project_item, message: "Question message") }
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

  it "creates jira comment from question" do
    expect(comment).
      to receive(:save).with(body: question.message).and_return(comment)

    described_class.new(question).call
  end

  it "sets jira internal comment id" do
    expect(comment).
      to receive(:save).with(body: question.message).and_return(comment)

    described_class.new(question).call
    question.reload

    expect(question.iid).to eq(123)
  end

  it "raises JIRACommentCreateError if comment was not created" do
    allow(comment).to receive(:save).and_return(nil)

    expect { described_class.new(question).call }.
      to raise_error(ProjectItem::RegisterQuestion::JIRACommentCreateError)
  end
end
