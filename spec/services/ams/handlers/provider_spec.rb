# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Provider do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(Provider::DeleteJob).to receive(:perform_later) }

      it "enqueues Provider::DeleteJob with the id" do
        described_class.call(action: "delete", resource: "organisation", data: { "id" => "1" })
        expect(Provider::DeleteJob).to have_received(:perform_later).with("1")
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "organisation" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false,
          "metadata" => { "modifiedAt" => "1700000000000" }
        }
      end

      before { allow(Provider::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues Provider::PcCreateOrUpdateJob with the payload, status and modified_at" do
        described_class.call(action: "create", resource: "organisation", data: data)
        expect(Provider::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published, Time.zone.at(1_700_000_000)
        )
      end
    end
  end
end
