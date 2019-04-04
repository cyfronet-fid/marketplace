# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }


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
      project_item = create(:project_item, project: project)
      project_item.new_change(status: :created, message: "ProjectItem created")
      project_item.new_change(status: :registered, message: "ProjectItem registered")

      mail = described_class.changed(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/has changed/)
      expect(encoded_body).to match(/from "created" to "registered"/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
      expect(mail.to).to contain_exactly(user.email)
    end

    it "notifies about new project_item message" do
      project_item = create(:project_item, project: project)
      project_item.new_change(status: :created, message: "ProjectItem created")
      project_item.new_change(status: :created, message: "New message")

      mail = described_class.changed(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Question about/)
      expect(encoded_body).to match(/A new message was added/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
      expect(mail.to).to contain_exactly(user.email)
    end
  end

  context "Rating service" do
    it "notifies about service rating possibility" do
      project_item = create(:project_item, project: project)

      mail = described_class.rate_service(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/EOSC Portal - Rate your service/)
      expect(encoded_body).to match(/Rate your service/)
      expect(encoded_body).to match(/#{project_item_url(project_item)}/)
    end
  end

  context "aod request" do
    it "notify if accepted" do
      project_item = create(:project_item, project: project)

      mail = described_class.aod_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/EGI Applications on Demand service approved/)
      expect(encoded_body).to include("This email is to inform you that your request to access the EGI\r\n" + \
                                      "Applications on Demand (AoD) service has been approved.")
    end

    it "notify if voucher accepted with voucher_id" do
      project_item = create(:project_item, project: project)
      project_item.voucher_id = "1234"

      mail = described_class.aod_voucher_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher approved/)
      expect(encoded_body).to match(/To redeem an Exoscale voucher, please follow these steps:/)
      expect(encoded_body).to have_content("1234")
    end

    it "notify if voucher accepted without voucher_id" do
      project_item = create(:project_item, project: project)
      project_item.voucher_id = "1234"

      mail = described_class.aod_voucher_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher approved/)
      expect(encoded_body).to match(/To redeem an Exoscale voucher, please follow these steps:/)
      expect(encoded_body).to have_content("Open your web browser at https://portal.exoscale.com/register?coupon=3D=\n1234=0D\n")
    end

    it "notify if voucher rejected with voucher_id" do
      project_item = create(:project_item, project: project)

      mail = described_class.aod_voucher_rejected(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher rejected/)
      expect(encoded_body).to match(/Cloud Computing Cluster \(EC3\) platform has been rejected./)
    end

    it "notify if voucher rejected without voucher_id" do
      project_item = create(:project_item, project: project)

      mail = described_class.aod_voucher_rejected(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher rejected/)
      expect(encoded_body).to match(/Cloud Computing Cluster \(EC3\) platform has been rejected./)
    end
  end
end
