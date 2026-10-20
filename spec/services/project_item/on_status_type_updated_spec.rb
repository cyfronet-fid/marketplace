# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::OnStatusTypeUpdated, :backend do
  let(:service) { create(:service, order_url: "http://not.empty") }
  let(:offer) { create(:offer, service: service) }

  context "for orderable? project_item" do
    let(:project_item) { build(:project_item, offer: offer, order_type: :order_required, order_url: "") }

    it "sends email on :waiting_for_response" do
      expect { project_item.update!(status_type: :waiting_for_response) }.to have_enqueued_mail(
        ProjectItemMailer,
        :waiting_for_response
      ).with(project_item)
    end

    it "sends email on :approved" do
      expect { project_item.update!(status_type: :approved) }.to have_enqueued_mail(ProjectItemMailer, :approved).with(
        project_item
      )
    end

    it "sends email on :ready" do
      expect { project_item.update!(status_type: :ready) }.to have_enqueued_mail(ProjectItemMailer, :ready_to_use).with(
        project_item
      )
    end

    it "sends email on :rejected" do
      expect { project_item.update!(status_type: :rejected) }.to have_enqueued_mail(ProjectItemMailer, :rejected).with(
        project_item
      )
    end

    it "sends email on :closed" do
      expect { project_item.update!(status_type: :closed) }.to have_enqueued_mail(ProjectItemMailer, :closed).with(
        project_item
      )
    end

    context "for aod?" do
      before { allow(project_item.service).to receive(:aod?).and_return(true) }

      it "sends email on :ready" do
        expect { project_item.update!(status_type: :ready) }.to have_enqueued_mail(
          ProjectItemMailer,
          :aod_accepted
        ).with(project_item)
      end

      context "for voucherable?" do
        before { allow(project_item.offer).to receive(:voucherable?).and_return(true) }

        it "sends email on :ready" do
          expect { project_item.update!(status_type: :ready) }.to have_enqueued_mail(
            ProjectItemMailer,
            :aod_voucher_accepted
          ).with(project_item)
        end

        it "sends email on :rejected" do
          expect { project_item.update!(status_type: :rejected) }.to have_enqueued_mail(
            ProjectItemMailer,
            :aod_voucher_rejected
          ).with(project_item)
        end
      end
    end
  end
end
