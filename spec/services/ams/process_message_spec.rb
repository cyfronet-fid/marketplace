# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::ProcessMessage do
  subject(:process_message) { described_class.call(subscription_name, message: message) }

  let(:message) { { "data" => { "id" => "123" } } }

  describe "#call" do
    {
      "catalogue" => Ams::Handlers::Catalogue,
      "datasource" => Ams::Handlers::Datasource,
      "deployable_application" => Ams::Handlers::DeployableService,
      "interoperability_record" => Ams::Handlers::Guideline,
      "organisation" => Ams::Handlers::Provider,
      "service" => Ams::Handlers::Service
    }.each do |resource, handler_klass|
      context "when the subscription name is for resource '#{resource}'" do
        let(:subscription_name) { "mp-#{resource}-create" }

        it "dispatches to #{handler_klass}" do
          allow(handler_klass).to receive(:call)
          process_message
          expect(handler_klass).to have_received(:call).with(action: "create", resource: resource,
                                                             data: message["data"])
        end
      end
    end

    context "when the subscription name has no prefix" do
      let(:subscription_name) { "service-update" }

      it "still parses resource and action correctly" do
        allow(Ams::Handlers::Service).to receive(:call)
        process_message
        expect(Ams::Handlers::Service).to have_received(:call).with(action: "update", resource: "service",
                                                                    data: message["data"])
      end
    end

    context "when the subscription resource has no registered handler" do
      let(:subscription_name) { "mp-infra_service-create" }

      it "returns false" do
        expect(process_message).to be(false)
      end

      it "logs a warning" do
        allow(Ams::Logger).to receive(:warn)
        process_message
        expect(Ams::Logger).to have_received(:warn).with(/No handler found for resource 'infra_service'/)
      end
    end

    it "returns the handler's result" do
      allow(Ams::Handlers::Service).to receive(:call).and_return(true)
      result = described_class.call("service-create", message: message)
      expect(result).to be(true)
    end
  end
end
