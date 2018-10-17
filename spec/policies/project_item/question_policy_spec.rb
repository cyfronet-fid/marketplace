# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::QuestionPolicy do
  let(:user) { create(:user) }
  let(:question) { ProjectItem::Question.new(project_item: project_item) }

  subject { described_class }


  permissions :create? do
    context "with active project_item" do
      let(:project_item) { create(:project_item, user: user, status: :created) }

      it "grants access for project_item owner when project_item is active" do
        expect(subject).to permit(user, question)
      end

      it "denies access for others" do
        expect(subject).to_not permit(build(:user), question)
      end
    end

    context "with inactive project_item" do
      let(:project_item) { create(:project_item, user: user, status: :ready) }

      it "denies access even for project_item owner" do
        expect(subject).to_not permit(user, question)
      end
    end
  end
end
