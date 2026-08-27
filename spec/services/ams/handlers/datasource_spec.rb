# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Datasource do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(Datasource::DeleteJob).to receive(:perform_later) }

      it "enqueues Datasource::DeleteJob with the id" do
        described_class.call(action: "delete", resource: "datasource", data: { "id" => "1" })
        expect(Datasource::DeleteJob).to have_received(:perform_later).with("1")
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "datasource" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false
        }
      end

      before { allow(Datasource::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues Datasource::PcCreateOrUpdateJob with the payload and status (no modified_at)" do
        described_class.call(action: "update", resource: "datasource", data: data)
        expect(Datasource::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published
        )
      end
    end
  end
end
