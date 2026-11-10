# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessageMailer, type: :mailer, backend: true do
  let(:project) { create(:project, name: "FancyOne") }
  let(:project_item) { create(:project_item, project: project) }

  describe "#new_message" do
    subject(:mail) { described_class.new_message(message) }

    context "when the message belongs to a project item" do
      let(:message) { create(:message, scope: :public, author_role: :provider, messageable: project_item) }

      it "is sent to the project item owner" do
        expect(mail.to).to contain_exactly(project_item.user.email)
      end

      it "has the service request subject" do
        expect(mail.subject).to eq("Question about your service access request in EOSC Portal Marketplace")
      end

      it "informs about the new message" do
        expect(mail.text_part.body.decoded).to include("A new message was added to your service request")
      end
    end

    context "when the message belongs to a project" do
      let(:message) { create(:message, scope: :public, author_role: :provider, messageable: project) }

      it "is sent to the project owner" do
        expect(mail.to).to contain_exactly(project.user.email)
      end

      it "has the project subject" do
        expect(mail.subject).to eq("Question about your Project FancyOne in EOSC Portal Marketplace")
      end

      it "informs about the new message" do
        expect(mail.text_part.body.decoded).to include("You have received a message related to your Project")
      end
    end
  end

  describe "#message_edited" do
    subject(:mail) { described_class.message_edited(message) }

    context "when the message belongs to a project item" do
      let(:message) { create(:message, scope: :public, author_role: :provider, messageable: project_item) }

      it "is sent to the project item owner" do
        expect(mail.to).to contain_exactly(project_item.user.email)
      end

      it "has the message updated subject" do
        expect(mail.subject).to eq("Message updated")
      end

      it "informs about the modification" do
        expect(mail.text_part.body.decoded).to include("has been modified by the service provider")
      end
    end

    context "when the message belongs to a project" do
      let(:message) { create(:message, scope: :public, author_role: :provider, messageable: project) }

      it "is sent to the project owner" do
        expect(mail.to).to contain_exactly(project.user.email)
      end

      it "informs about the modification" do
        expect(mail.text_part.body.decoded).to include("has been modified by the service provider")
      end
    end
  end
end
