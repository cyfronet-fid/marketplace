# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy, backend: true do
  let(:user) { create(:user) }
  let(:project_with_project_item) { create(:project) { |project| create(:project_item, project: project) } }
  let(:project_with_ended_project_item) do
    create(:project) { |project| create(:project_item, project: project, status: "closed", status_type: :closed) }
  end

  subject { described_class }

  permissions :show?, :edit?, :update? do
    it "grants access for owner and active service" do
      expect(subject).to permit(user, build(:project, user: user))
    end
    it "denied access for not owner" do
      expect(subject).to_not permit(user, build(:project))
    end
  end

  permissions :show? do
    it "grants access for owner and active service" do
      expect(subject).to permit(user, build(:project, user: user))
    end
  end

  permissions :edit?, :update? do
    it "denied access for archived service" do
      expect(subject).to_not permit(user, build(:project, status: :archived))
    end
  end

  permissions :archive? do
    it "denied access when service have not ended projects_items" do
      expect(subject).to_not permit(user, project_with_project_item)
    end
    it "grant access when service have all ended projects_items" do
      expect(subject).to_not permit(user, project_with_ended_project_item)
    end
    it "denied access when service is already archived" do
      expect(subject).to_not permit(user, build(:project, status: :archived))
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
