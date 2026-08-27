# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Service do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(Service::DeleteJob).to receive(:perform_later) }

      it "enqueues Service::DeleteJob with the id" do
        described_class.call(action: "delete", resource: "service", data: { "id" => "1" })
        expect(Service::DeleteJob).to have_received(:perform_later).with("1")
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "service" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false,
          "metadata" => { "modifiedAt" => "1700000000000" }
        }
      end

      before { allow(Service::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues Service::PcCreateOrUpdateJob with the payload, status and modified_at" do
        described_class.call(action: "create", resource: "service", data: data)
        expect(Service::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published, Time.zone.at(1_700_000_000)
        )
      end
    end
  end
end
