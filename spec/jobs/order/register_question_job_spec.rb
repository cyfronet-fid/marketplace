# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::RegisterQuestionJob do
  let(:order_owner) { create(:user) }
  let(:order) { create(:order, user: order_owner) }
  let(:register_service) { instance_double(Order::RegisterQuestion) }

  QUESTION_TEXT = "Question text"

  def make_question(author)
    create(:order_change,
                  message: QUESTION_TEXT,
                  order: order,
                  author: author)
  end

  it "triggers registration process for order owner question" do
    question = make_question(order_owner)
    expect(Order::RegisterQuestion).to receive(:new).
      with(order, QUESTION_TEXT).and_return(register_service)
    expect(register_service).to receive(:call)

    described_class.perform_now(question)
  end

  it "does nothing when change is not a question" do
    question = make_question(nil)
    expect(Order::RegisterQuestion).to_not receive(:new)

    described_class.perform_now(question)
  end

  it "handles exception thrown by Order::RegisterQuestion" do
    question = make_question(order_owner)
    expect(Order::RegisterQuestion).to receive(:new).
        with(order, QUESTION_TEXT).and_return(register_service)
    expect(register_service).to receive(:call).and_raise(Order::RegisterQuestion::JIRACommentCreateError.new(order))

    described_class.perform_now(question)
  end
end
