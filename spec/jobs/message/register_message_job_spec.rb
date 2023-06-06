# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message::RegisterMessageJob, backend: true do
  let(:project_item_owner) { create(:user) }
  let(:project) { create(:project, user: project_item_owner) }
  let(:project_item) { create(:project_item, project: project) }
  let(:register_service) { instance_double(Message::RegisterMessage) }

  def make_message(author)
    create(
      :message,
      messageable: project_item,
      message: "message msg",
      author: author,
      author_role: author.nil? ? :provider : :user,
      scope: :public
    )
  end

  it "triggers registration process for project_item owner message" do
    message = make_message(project_item_owner)
    allow(Message::RegisterMessage).to receive(:new).with(message).and_return(register_service)

    expect(register_service).to receive(:call)

    described_class.perform_now(message)
  end

  it "does nothing when message is not a question" do
    message = make_message(nil)
    expect(Message::RegisterMessage).to_not receive(:new)

    described_class.perform_now(message)
  end

  it "handles exception thrown by Message::RegisterMessage" do
    message = make_message(project_item_owner)
    allow(Message::RegisterMessage).to receive(:new).with(message).and_return(register_service)

    expect(register_service).to receive(:call).and_raise(
      Message::RegisterMessage::JIRACommentCreateError.new(project_item)
    )

    described_class.perform_now(message)
  end
end
