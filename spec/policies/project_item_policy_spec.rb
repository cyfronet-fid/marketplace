# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemPolicy, backend: true do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :index?, :new? do
    it "grants access for logged in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :create? do
    it "grants access to create item in owned project" do
      expect(subject).to permit(user, build(:project_item, project: build(:project, user: user)))
    end
  end

  permissions :show? do
    it "grants access for project_item owner" do
      expect(subject).to permit(user, build(:project_item, project: build(:project, user: user)))
    end

    it "denies to see other user owners" do
      expect(subject).to_not permit(user, build(:project_item))
    end
  end
end
