# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Catalogue do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "does not enqueue any job (catalogue deletion is not supported)" do
        described_class.call(action: "delete", resource: "catalogue", data: { "id" => "1" })
        expect(Catalogue::PcCreateOrUpdateJob).not_to have_received(:perform_later)
      end

      it "logs that the deletion was ignored" do
        allow(Ams::Logger).to receive(:info)
        described_class.call(action: "delete", resource: "catalogue", data: { "id" => "1" })
        expect(Ams::Logger).to have_received(:info).with(/Ignoring catalogue delete for id '1'/)
      end

      it "returns nil so the message keeps redelivering" do
        result = described_class.call(action: "delete", resource: "catalogue", data: { "id" => "1" })
        expect(result).to be_nil
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "catalogue" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false,
          "metadata" => { "modifiedAt" => "1700000000000" }
        }
      end

      before { allow(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues Catalogue::PcCreateOrUpdateJob with the payload, status and modified_at" do
        described_class.call(action: "create", resource: "catalogue", data: data)
        expect(Catalogue::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published, Time.zone.at(1_700_000_000)
        )
      end
    end
  end
end
