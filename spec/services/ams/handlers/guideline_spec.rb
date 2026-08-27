# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Guideline do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(Guideline::DeleteJob).to receive(:perform_later) }

      it "enqueues Guideline::DeleteJob with the id" do
        described_class.call(action: "delete", resource: "interoperability_record", data: { "id" => "1" })
        expect(Guideline::DeleteJob).to have_received(:perform_later).with("1")
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "interoperabilityRecord" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false,
          "metadata" => { "modifiedAt" => "1700000000000" }
        }
      end

      before { allow(Guideline::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues Guideline::PcCreateOrUpdateJob with the payload, status and modified_at" do
        described_class.call(action: "update", resource: "interoperability_record", data: data)
        expect(Guideline::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published, Time.zone.at(1_700_000_000)
        )
      end
    end
  end
end
