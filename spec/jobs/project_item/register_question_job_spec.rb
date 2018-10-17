# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::RegisterQuestionJob do
  let(:project_item_owner) { create(:user) }
  let(:project_item) { create(:project_item, user: project_item_owner) }
  let(:register_service) { instance_double(ProjectItem::RegisterQuestion) }

  def make_question(author)
    create(:order_change,
           message: "question msg",
           project_item: project_item,
           author: author)
  end

  it "triggers registration process for project_item owner question" do
    question = make_question(project_item_owner)
    allow(ProjectItem::RegisterQuestion).to receive(:new).
      with(question).and_return(register_service)

    expect(register_service).to receive(:call)

    described_class.perform_now(question)
  end

  it "does nothing when change is not a question" do
    question = make_question(nil)
    expect(ProjectItem::RegisterQuestion).to_not receive(:new)

    described_class.perform_now(question)
  end

  it "handles exception thrown by ProjectItem::RegisterQuestion" do
    question = make_question(project_item_owner)
    allow(ProjectItem::RegisterQuestion).to receive(:new).
        with(question).and_return(register_service)

    expect(register_service).to receive(:call).
      and_raise(ProjectItem::RegisterQuestion::JIRACommentCreateError.new(project_item))

    described_class.perform_now(question)
  end
end
