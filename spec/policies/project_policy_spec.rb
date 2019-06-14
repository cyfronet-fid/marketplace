# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy do
  let(:user) { create(:user) }
  let(:project_with_project_item) do
    create(:project) do |project|
      create(:project_item,  project: project)
    end
  end
  subject { described_class }

  permissions :show?, :edit?, :update? do
    it "grants access for owner" do
      expect(subject).to permit(user, build(:project, user: user))
    end
    it "denied access for owner" do
      expect(subject).to_not permit(user, build(:project))
    end
  end

  permissions :destroy? do
    it "grants access for owner and without project item" do
      expect(subject).to permit(user, build(:project, user: user))
    end
    it "denied access when project have connected project items" do
      expect(subject).to_not permit(user, project_with_project_item)
    end
  end

  it "returns only user projects" do
    owned_project = create(:project, user: user)
    _other_user_project = create(:project)

    scope = described_class::Scope.new(user, Project)

    expect(scope.resolve).to contain_exactly(owned_project)
  end
end
