# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::DeployableService do
  describe "#call" do
    context "when the action is 'delete'" do
      before { allow(DeployableService::DeleteJob).to receive(:perform_later) }

      it "enqueues DeployableService::DeleteJob with the id" do
        described_class.call(action: "delete", resource: "deployable_application", data: { "id" => "1" })
        expect(DeployableService::DeleteJob).to have_received(:perform_later).with("1")
      end
    end

    context "when the action is 'create' or 'update'" do
      let(:data) do
        {
          "id" => "1",
          "deployableApplication" => { "name" => "Foo" },
          "active" => true,
          "suspended" => false
        }
      end

      before { allow(DeployableService::PcCreateOrUpdateJob).to receive(:perform_later) }

      it "enqueues DeployableService::PcCreateOrUpdateJob with the payload and status (no modified_at)" do
        described_class.call(action: "create", resource: "deployable_application", data: data)
        expect(DeployableService::PcCreateOrUpdateJob).to have_received(:perform_later).with(
          { "name" => "Foo" }, :published
        )
      end
    end
  end
end
