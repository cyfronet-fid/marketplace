# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemMailer, type: :mailer do
  context "project_item created" do
    let(:project_item) { build(:project_item, id: 1) }
    let(:mail) { described_class.created(project_item).deliver_now }

    it "sends email to project_item owner" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.to).to contain_exactly(project_item.user.email)
    end

    it "email contains project_item details" do
      encoded_body = mail.body.encoded

      expect(encoded_body).to match(/#{project_item.user.full_name}/)
      expect(encoded_body).to match(/#{project_item.service.title}/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
    end
  end

  context "project_item change" do
    it "notifies about project_item status change" do
      project_item = create(:project_item)
      project_item.new_change(status: :created, message: "ProjectItem created")
      project_item.new_change(status: :registered, message: "ProjectItem registered")

      mail = described_class.changed(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/status changed/)
      expect(encoded_body).to match(/from "created" to "registered"/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
    end

    it "notifies about new project_item message" do
      project_item = create(:project_item)
      project_item.new_change(status: :created, message: "ProjectItem created")
      project_item.new_change(status: :created, message: "New message")

      mail = described_class.changed(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/new message/)
      expect(encoded_body).to match(/New message was added/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
    end
  end

  context "Rating service" do
    it "notifies about service rating possibility" do
      project_item = create(:project_item)

      mail = described_class.rate_service(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/EOSC Portal - Rate your service/)
      expect(encoded_body).to match(/Rate your service/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
    end
  end
end
