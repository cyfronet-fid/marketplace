# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::DeactivateJob do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:deactivate_service) { instance_double(ProjectItem::Deactivate) }
  let(:project_item) {
    project_item = create(:open_access_project_item, project: project).tap do |project_item|
      expect(ProjectItem::Deactivate).to receive(:new).
              with(project_item).and_return(deactivate_service)
    end
  }

  it "triggers deactivation process for project_item" do
    expect(deactivate_service).to receive(:call)
    described_class.perform_now(project_item)
  end
end
