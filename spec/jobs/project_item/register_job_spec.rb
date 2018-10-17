# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::RegisterJob do
  let(:project_item_owner) { create(:user) }
  let(:register_service) { instance_double(ProjectItem::Register) }
  let(:project_item) {
    project_item = create(:project_item, user: project_item_owner)
    expect(ProjectItem::Register).to receive(:new).
        with(project_item).and_return(register_service)
    next project_item
  }

  it "triggers registration process for project_item" do
    expect(register_service).to receive(:call)
    described_class.perform_now(project_item)
  end

  it "handles exception thrown by ProjectItem::Register" do
    expect(register_service).to receive(:call).and_raise(ProjectItem::Register::JIRAIssueCreateError.new(project_item))
    described_class.perform_now(project_item)
  end
end
