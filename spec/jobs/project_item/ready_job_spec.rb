# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::ReadyJob, backend: true do
  let(:project_item_owner) { create(:user) }
  let(:project) { create(:project, user: project_item_owner) }
  let(:ready_service) { instance_double(ProjectItem::Ready) }
  let(:project_item) do
    project_item = create(:project_item, project: project)
    allow(ProjectItem::Ready).to receive(:new).with(project_item, nil).and_return(ready_service)
    next project_item
  end

  it "triggers ready process for project_item" do
    expect(ready_service).to receive(:call)
    described_class.perform_now(project_item)
  end

  it "should recast exceptions cast by ProjectItem::Ready" do
    error = Jira::Client::JIRAIssueCreateError.new(project_item)

    expect(ready_service).to receive(:call).and_raise(error)

    expect { described_class.perform_now(project_item) }.to raise_error(error)
  end
end
