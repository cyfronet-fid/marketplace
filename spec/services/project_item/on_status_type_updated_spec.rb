# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::OnStatusTypeUpdated, backend: true do
  let(:service) { create(:service, order_url: "http://not.empty") }
  let(:offer) { create(:offer, service: service) }

  context "for orderable? project_item" do
    let(:project_item) { build(:project_item, offer: offer, order_type: :order_required, order_url: "") }

    it "sends email on :waiting_for_response" do
      expect { project_item.update!(status_type: :waiting_for_response) }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq(
        "Status of your service access request in the " + "EOSC Portal Marketplace has changed to WAITING FOR RESPONSE"
      )
    end

    it "sends email on :approved" do
      expect { project_item.update!(status_type: :approved) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq(
        "Status of your service access request in the EOSC Portal Marketplace has changed to APPROVED"
      )
    end

    it "sends email on :ready" do
      expect { project_item.update!(status_type: :ready) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq(
        "Status of your service access request in the EOSC Portal Marketplace has changed to READY TO USE"
      )
    end

    it "sends email on :rejected" do
      expect { project_item.update!(status_type: :rejected) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq(
        "Status of your service access request in the EOSC Portal Marketplace has changed to REJECTED"
      )
    end

    it "sends email on :closed" do
      expect { project_item.update!(status_type: :closed) }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq(
        "Status of your service access request in the EOSC Portal Marketplace has changed to CLOSED"
      )
    end

    context "for aod?" do
      before { allow(project_item.service).to receive(:aod?).and_return(true) }

      it "sends email on :ready" do
        expect { project_item.update!(status_type: :ready) }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(ActionMailer::Base.deliveries.last.subject).to eq("EGI Applications on Demand service approved")
      end

      context "for voucherable?" do
        before { allow(project_item.offer).to receive(:voucherable?).and_return(true) }

        it "sends email on :ready" do
          expect { project_item.update!(status_type: :ready) }.to change { ActionMailer::Base.deliveries.count }.by(1)

          expect(ActionMailer::Base.deliveries.last.subject).to eq(
            "Elastic Cloud Compute Cluster (EC3) service with voucher approved"
          )
        end

        it "sends email on :rejected" do
          expect { project_item.update!(status_type: :rejected) }.to change { ActionMailer::Base.deliveries.count }.by(
            1
          )

          expect(ActionMailer::Base.deliveries.last.subject).to eq(
            "Elastic Cloud Compute Cluster (EC3) service with voucher rejected"
          )
        end
      end
    end
  end
end
