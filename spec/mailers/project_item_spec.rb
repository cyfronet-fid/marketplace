# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemMailer, type: :mailer, backend: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:project_item) { create(:project_item, project: project) }

  context "project_item created" do
    let(:mail) { described_class.created(project_item).deliver_now }

    it "sends email to project_item owner" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.to).to contain_exactly(project_item.user.email)
    end

    it "email contains project_item details" do
      encoded_body = mail.body.encoded

      expect(encoded_body).to match(/#{project_item.user.full_name}/)
      expect(encoded_body).to match(/#{project_item.service.name}/)
      expect(encoded_body).to match(/#{project_service_url(project, project_item)}/)
    end
  end

  context "project_item change" do
    before(:each) do
      project_item.new_status(status: "custom_created", status_type: :created)
      project_item.new_status(status: "custom_registered", status_type: :registered)
    end

    it "notifies about project_item status change to waiting_for_response" do
      project_item.new_status(status: "custom_waiting_for_response", status_type: :waiting_for_response)

      mail = described_class.waiting_for_response(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(
        "Status of your service access request " \
          "in the EOSC Portal Marketplace has changed to WAITING FOR RESPONSE"
      )
      expect(encoded_body).to match(/You have received a message from a customer service expert related/)
      expect(encoded_body).to match(/#{project_services_url(project)}/)
      expect(mail.to).to contain_exactly(user.email)
    end

    it "notifies about project_item status change to rejected" do
      project_item.new_status(status: "custom_rejected", status_type: :rejected)

      mail = described_class.rejected(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(
        "Status of your service access request in the EOSC Portal Marketplace " \
          "has changed to REJECTED"
      )
      expect(encoded_body).to match("rejected.")
      expect(encoded_body).to match(/#{project_service_conversation_url(project, project_item)}/)
      expect(mail.to).to contain_exactly(user.email)
    end

    it "notifies about project_item status change to closed" do
      project_item.new_status(status: "custom_closed", status_type: :closed)

      mail = described_class.closed(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(
        "Status of your service access request in the EOSC Portal Marketplace " \
          "has changed to CLOSED"
      )
      expect(encoded_body).to match(/has been closed/)
      expect(encoded_body).to match(/#{project_service_conversation_url(project, project_item)}/)
      expect(mail.to).to contain_exactly(user.email)
    end

    it "notifies about project_item status change to approved" do
      project_item.new_status(status: "custom_approved", status_type: :approved)

      mail = described_class.approved(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(
        "Status of your service access request in the EOSC Portal Marketplace " \
          "has changed to APPROVED"
      )
      expect(encoded_body).to match(/is approved/)
      expect(encoded_body).to match(/#{project_service_url(project, project_item)}/)
      expect(mail.to).to contain_exactly(user.email)
    end
  end

  context "Rating service" do
    it "notifies about service rating possibility" do
      mail = described_class.rate_service(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/EOSC Portal - Rate your service/)
      expect(encoded_body).to match(/Rate your service/)
      expect(encoded_body).to match(/#{project_service_url(project, project_item)}/)
    end
  end

  context "aod request" do
    it "notify if accepted" do
      mail = described_class.aod_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/EGI Applications on Demand service approved/)
      expect(encoded_body).to include(
        "This email is to inform you that your request to access the EGI\r\n" \
          "Applications on Demand (AoD) service has been approved."
      )
    end

    it "notify if voucher accepted with voucher_id" do
      project_item.voucher_id = "1234"

      mail = described_class.aod_voucher_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher approved/)
      expect(encoded_body).to match(/To redeem an Exoscale voucher:/)
      expect(encoded_body).to have_content("1234")
    end

    it "notify if voucher accepted with user_secrets voucher_id" do
      project_item.user_secrets["voucher_id"] = "1234"

      mail = described_class.aod_voucher_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher approved/)
      expect(encoded_body).to match(/To redeem an Exoscale voucher:/)
      expect(encoded_body).to have_content("1234")
    end

    it "notify if voucher accepted without voucher_id" do
      project_item.voucher_id = "1234"

      mail = described_class.aod_voucher_accepted(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher approved/)
      expect(encoded_body).to match(/To redeem an Exoscale voucher:/)
      expect(encoded_body).to have_content(
        "Open your web browser at https://portal.exoscale.com/register?coupon=3D=\r\n1234\r\n"
      )
    end

    it "notify if voucher rejected with voucher_id" do
      mail = described_class.aod_voucher_rejected(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher rejected/)
      expect(encoded_body).to match(/Cloud Computing Cluster \(EC3\) platform has been rejected./)
    end

    it "notify if voucher rejected without voucher_id" do
      mail = described_class.aod_voucher_rejected(project_item).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/Elastic Cloud Compute Cluster \(EC3\) service with voucher rejected/)
      expect(encoded_body).to match(/Cloud Computing Cluster \(EC3\) platform has been rejected./)
    end
  end
end
