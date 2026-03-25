# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::ManageMessage do
  let(:logger) { Logger.new(nil) }
  let(:registry_url) { "http://api" }
  let(:token) { "token" }

  describe "#call" do
    context "when resource is a service" do
      let(:message_body) do
        {
          "service" => {
            "id" => "123",
            "name" => "Test"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls Service::PcCreateOrUpdateJob for create action" do
        expect(Service::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "123", "name" => "Test" },
          registry_url,
          :published,
          be_a(Time),
          token
        )
        Ams::ManageMessage.new(message_body, "prefix.service.create", registry_url, logger, token).call
      end

      it "calls Service::PcCreateOrUpdateJob for create action (hyphenated topic)" do
        expect(Service::PcCreateOrUpdateJob).to receive(:perform_later)
        Ams::ManageMessage.new(message_body, "mp-service-create", registry_url, logger, token).call
      end

      it "calls Service::DeleteJob for delete action" do
        expect(Service::DeleteJob).to receive(:perform_later).with("123")
        Ams::ManageMessage.new(message_body, "prefix.service.delete", registry_url, logger, token).call
      end
    end

    context "when resource is a provider" do
      let(:message_body) do
        {
          "provider" => {
            "id" => "P1",
            "name" => "Prov"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls Provider::PcCreateOrUpdateJob for update action" do
        expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "P1", "name" => "Prov" },
          :published,
          be_a(Time)
        )
        Ams::ManageMessage.new(message_body, "prefix.provider.update", registry_url, logger, token).call
      end

      it "calls Provider::DeleteJob for delete action" do
        expect(Provider::DeleteJob).to receive(:perform_later).with("P1")
        Ams::ManageMessage.new(message_body, "prefix.provider.delete", registry_url, logger, token).call
      end
    end

    context "when resource is a catalogue" do
      let(:message_body) do
        {
          "catalogue" => {
            "id" => "C1",
            "name" => "Cat"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls Catalogue::PcCreateOrUpdateJob for create action" do
        expect(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "C1", "name" => "Cat" },
          :published,
          be_a(Time)
        )
        Ams::ManageMessage.new(message_body, "prefix.catalogue.create", registry_url, logger, token).call
      end
    end

    context "when resource is a datasource" do
      let(:message_body) do
        {
          "datasource" => {
            "id" => "D1",
            "name" => "DS"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls Datasource::PcCreateOrUpdateJob for update action" do
        expect(Datasource::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "D1", "name" => "DS" },
          :published
        )
        Ams::ManageMessage.new(message_body, "prefix.datasource.update", registry_url, logger, token).call
      end

      it "calls Datasource::DeleteJob for delete action" do
        expect(Datasource::DeleteJob).to receive(:perform_later).with("D1")
        Ams::ManageMessage.new(message_body, "prefix.datasource.delete", registry_url, logger, token).call
      end
    end

    context "when resource is a deployable_service" do
      let(:message_body) do
        {
          "deployableService" => {
            "id" => "DS1",
            "name" => "Dep"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls DeployableService::PcCreateOrUpdateJob for create action" do
        expect(DeployableService::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "DS1", "name" => "Dep" },
          :published
        )
        Ams::ManageMessage.new(message_body, "prefix.deployable_service.create", registry_url, logger, token).call
      end

      it "calls DeployableService::DeleteJob for delete action" do
        expect(DeployableService::DeleteJob).to receive(:perform_later).with("DS1")
        Ams::ManageMessage.new(message_body, "prefix.deployable_service.delete", registry_url, logger, token).call
      end
    end

    context "when resource is an infra_service" do
      let(:message_body) do
        {
          "infraService" => {
            "id" => "IS1",
            "name" => "Infra"
          },
          "active" => true,
          "suspended" => false,
          "metadata" => {
            "modifiedAt" => "1600000000000"
          }
        }.to_json
      end

      it "calls Service::PcCreateOrUpdateJob for create action" do
        expect(Service::PcCreateOrUpdateJob).to receive(:perform_later).with(
          { "id" => "IS1", "name" => "Infra" },
          registry_url,
          :published,
          be_a(Time),
          token
        )
        Ams::ManageMessage.new(message_body, "prefix.infra_service.create", registry_url, logger, token).call
      end
    end

    it "maps interoperability_record to guideline and calls Guideline::PcCreateOrUpdateJob" do
      body = {
        "guideline" => {
          "id" => "G1",
          "title" => "Rule"
        },
        "active" => true,
        "suspended" => false,
        "metadata" => {
          "modifiedAt" => "1600000000000"
        }
      }.to_json

      expect(Guideline::PcCreateOrUpdateJob).to receive(:perform_later).with(
        { "id" => "G1", "title" => "Rule" },
        :published,
        be_a(Time)
      )

      Ams::ManageMessage.new(body, "prefix.interoperability_record.update", registry_url, logger, token).call
    end

    it "raises WrongMessageError for unknown resource type" do
      body = { "unknown" => { "id" => "U1" } }.to_json
      expect(Sentry).to receive(:capture_exception).with(be_a(Importable::WrongMessageError))
      Ams::ManageMessage.new(body, "prefix.unknown.create", registry_url, logger, token).call
    end

    context "when body is invalid" do
      it "handles ResourceParseError when resource is missing" do
        body = { "other" => { "id" => "1" } }.to_json
        # resource_type will be 'service', but body['service'] is nil
        # It logs a warning via 'warn' method in ManageMessage
        expect(logger).to receive(:warn).with(/Resource parse error: Cannot parse resource: service/)
        Ams::ManageMessage.new(body, "prefix.service.create", registry_url, logger, token).call
      end

      it "handles JSON::ParserError when body is not JSON" do
        # JSON.parse will raise error which is not caught by specific rescues in call
        # but let's see how it behaves. The 'call' method doesn't rescue JSON::ParserError.
        expect do
          Ams::ManageMessage.new("invalid json", "prefix.service.create", registry_url, logger, token).call
        end.to raise_error(JSON::ParserError)
      end
    end
  end
end
