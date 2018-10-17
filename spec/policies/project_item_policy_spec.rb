# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemPolicy do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :index?, :create?, :new? do
    it "grants access for logged in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :show? do
    it "grants access for project_item owner" do
      expect(subject).to permit(user, build(:project_item, user: user))
    end

    it "denies to see other user owners" do
      expect(subject).to_not permit(user, build(:project_item))
    end
  end

  it "returns only user project_items" do
    service = create(:service)
    owned_project_item = create(:project_item, service: service, user: user)
    _other_user_project_item = create(:project_item, service: service)

    scope = described_class::Scope.new(user, ProjectItem.all)

    expect(scope.resolve).to contain_exactly(owned_project_item)
  end
end
