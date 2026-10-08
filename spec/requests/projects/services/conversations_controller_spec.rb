# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::Services::ConversationsController, type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:project_item) { create(:project_item, project: project) }

  before do
    allow(Mp::Variant).to receive(:marketplace?).and_return(marketplace)
    login_as(user)
    post project_service_conversation_path(project, project_item), params: { message: { message: "Hello" } }
  end

  context "when running as marketplace" do
    let(:marketplace) { true }

    it "saves the message" do
      expect(project_item.messages.count).to eq(1)
    end

    it "does not forward the message to BOS" do
      expect(Bos::PostMessageJob).not_to have_been_enqueued
    end
  end

  context "when running as another variant" do
    let(:marketplace) { false }

    it "forwards the message to BOS" do
      expect(Bos::PostMessageJob).to have_been_enqueued.with(project_item.messages.first)
    end
  end
end
