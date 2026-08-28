# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::Handlers::Base do
  let(:handler_class) do
    Class.new(described_class) do
      attr_reader :deleted_id, :updated_payload

      def delete(id)
        @deleted_id = id
      end

      def create_or_update(payload)
        @updated_payload = payload
      end
    end
  end

  let(:handler) { handler_class.send(:new, action: action, resource: resource, data: data) }
  let(:resource) { "service" }

  describe "#call" do
    context "when the action is not in ALLOWED_ACTIONS" do
      let(:action) { "publish" }
      let(:data) { { "id" => "1" } }

      it "returns nil" do
        expect(handler.call).to be_nil
      end

      it "does not dispatch to delete" do
        handler.call
        expect(handler.deleted_id).to be_nil
      end

      it "does not dispatch to create_or_update" do
        handler.call
        expect(handler.updated_payload).to be_nil
      end

      it "logs a warning" do
        allow(Ams::Logger).to receive(:warn)
        handler.call
        expect(Ams::Logger).to have_received(:warn).with(/disallowed action 'publish'/)
      end
    end

    context "when data['id'] is blank" do
      let(:action) { "create" }
      let(:data) { {} }

      it "returns nil" do
        expect(handler.call).to be_nil
      end

      it "does not dispatch to create_or_update" do
        handler.call
        expect(handler.updated_payload).to be_nil
      end

      it "logs a warning" do
        allow(Ams::Logger).to receive(:warn)
        handler.call
        expect(Ams::Logger).to have_received(:warn).with(/missing id/)
      end
    end

    context "when the action is 'delete'" do
      let(:action) { "delete" }
      let(:data) { { "id" => "42" } }

      it "calls delete with data['id']" do
        handler.call
        expect(handler.deleted_id).to eq("42")
      end
    end

    context "when the action is 'create'" do
      let(:action) { "create" }
      let(:data) { { "id" => "42", "service" => { "name" => "Foo" } } }

      it "calls create_or_update with the resource-keyed payload" do
        handler.call
        expect(handler.updated_payload).to eq("name" => "Foo")
      end
    end

    context "when the action is 'update'" do
      let(:action) { "update" }
      let(:data) { { "id" => "42", "service" => { "name" => "Foo" } } }

      it "calls create_or_update with the resource-keyed payload" do
        handler.call
        expect(handler.updated_payload).to eq("name" => "Foo")
      end
    end

    context "when resource has underscores (camelCase lookup key)" do
      let(:action) { "create" }
      let(:resource) { "deployable_application" }
      let(:data) { { "id" => "1", "deployableApplication" => { "name" => "Bar" } } }

      it "camelizes the resource name to find the nested payload" do
        handler.call
        expect(handler.updated_payload).to eq("name" => "Bar")
      end
    end
  end

  describe "#modified_at" do
    let(:action) { "create" }

    context "when metadata.modifiedAt is present" do
      let(:data) { { "id" => "1", "metadata" => { "modifiedAt" => "1700000000000" } } }

      it "derives it from the millisecond-epoch string" do
        expect(handler.send(:modified_at)).to eq(Time.zone.at(1_700_000_000))
      end
    end

    context "when metadata.modifiedAt has a non-zero millisecond component" do
      let(:data) { { "id" => "1", "metadata" => { "modifiedAt" => "1700000000123" } } }

      it "retains the millisecond precision instead of truncating to the second" do
        result = handler.send(:modified_at)
        expect([result.to_i, result.usec]).to eq([1_700_000_000, 123_000])
      end
    end

    context "when metadata.modifiedAt is absent" do
      let(:data) { { "id" => "1" } }

      it "falls back to the current time" do
        travel_to Time.zone.local(2026, 1, 1, 12, 0, 0) do
          expect(handler.send(:modified_at)).to eq(Time.zone.now)
        end
      end
    end
  end
end
