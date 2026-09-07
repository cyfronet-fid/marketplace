# frozen_string_literal: true

require "rails_helper"
require "stomp"

describe Jms::ManageMessage, :backend do
  let(:logger) { Logger.new($stdout) }

  context "when receiving a service create/update message" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) { create(:jms_json_service) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.service.update" }) }

    it "enqueues a publish job for the service" do
      expect { call }
        .to have_enqueued_job(Service::PcCreateOrUpdateJob).with(resource["service"], :published, modified_at)
        .and output.to_stdout
    end
  end

  context "when receiving a provider update message" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) { create(:jms_json_provider) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.provider.update" }) }

    it "enqueues a publish job for the provider" do
      expect { call }
        .to have_enqueued_job(Provider::PcCreateOrUpdateJob).with(resource["provider"], :published, modified_at)
        .and output.to_stdout
    end
  end

  context "when routing an organisation message to provider jobs" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) do
      parsed = JSON.parse(create(:jms_json_provider))
      parsed["resource"]["organisation"] = parsed["resource"].delete("provider")
      parsed.to_json
    end
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.organisation.update" }) }

    it "enqueues a publish job for the provider" do
      expect { call }
        .to have_enqueued_job(Provider::PcCreateOrUpdateJob).with(resource["organisation"], :published, modified_at)
    end
  end

  context "when routing a deployable_application message to deployable service jobs" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) do
      { resource: { active: true, suspended: false, deployableApplication: create(:jms_deployable_service) } }.to_json
    end
    let(:resource) { JSON.parse(body)["resource"] }
    let(:message) do
      double(body: body, headers: { "destination" => "/topic/registry.deployable_application.create" })
    end

    it "enqueues a publish job for the deployable service" do
      expect { call }
        .to have_enqueued_job(DeployableService::PcCreateOrUpdateJob)
        .with(resource["deployableApplication"], :published, kind_of(Time))
    end
  end

  context "when routing an interoperability_record message to guideline jobs" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) do
      {
        resource: {
          active: true,
          suspended: false,
          metadata: { modifiedAt: 1_600_000_000_000 },
          interoperabilityRecord: { id: "G1", title: "Rule" }
        }
      }.to_json
    end
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) do
      double(body: body, headers: { "destination" => "/topic/registry.interoperability_record.update" })
    end

    it "enqueues a publish job for the guideline" do
      expect { call }.to have_enqueued_job(Guideline::PcCreateOrUpdateJob)
        .with(resource["interoperabilityRecord"], :published, modified_at)
    end
  end

  context "when receiving an update to a draft provider message" do
    subject(:call) { described_class.new(message, logger).call }

    let(:body) { build(:jms_json_draft_provider) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.provider.update" }) }

    it "enqueues an unpublish job for the provider" do
      expect { call }
        .to have_enqueued_job(Provider::PcCreateOrUpdateJob).with(resource["provider"], :unpublished, modified_at)
        .and output.to_stdout
    end
  end

  context "when receiving an update to a rejected provider message" do
    subject(:call) { described_class.new(message, logger).call }

    let(:body) { build(:jms_json_rejected_provider) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.provider.update" }) }

    it "enqueues an unpublish job for the provider" do
      expect { call }
        .to have_enqueued_job(Provider::PcCreateOrUpdateJob).with(resource["provider"], :unpublished, modified_at)
        .and output.to_stdout
    end
  end

  context "when receiving a provider delete message" do
    subject(:call) { described_class.new(message, logger).call }

    let(:provider) { create(:provider) }
    let(:message) do
      double(body: create(:jms_json_provider), headers: { "destination" => "/topic/registry.provider.delete" })
    end

    before { create(:provider_source, provider: provider, eid: "cyfronet") }

    it "enqueues a delete job for the provider" do
      expect { call }.to have_enqueued_job(Provider::DeleteJob).with("eosc.cyfronet").and output.to_stdout
    end
  end

  context "when receiving a service delete message" do
    subject(:call) { described_class.new(message, logger).call }

    let(:service) { create(:service) }
    let(:message) do
      double(body: create(:jms_json_service), headers: { "destination" => "/topic/registry.service.delete" })
    end

    before { create(:service_source, service: service, eid: "eosc.tp.openminted_catalogue_of_corpora_2") }

    it "enqueues a delete job for the service" do
      expect { call }
        .to have_enqueued_job(Service::DeleteJob).with("eosc.tp.openminted_catalogue_of_corpora_2").and output.to_stdout
    end
  end

  context "when the message resource cannot be parsed" do
    subject(:call) { described_class.new(message, logger).call }

    let(:message) do
      double(body: { some_happy_key: "some_happy_value" }.to_json, headers: { "destination" => "aaaa.update" })
    end

    it "does not raise an error" do
      expect { call }.to output.to_stdout
    end
  end

  context "when the message type is out of scope" do
    subject(:call) { described_class.new(message, logger).call }

    let(:message) do
      double(
        body: { resource: { adapter: { id: "A1", name: "Adapter" } } }.to_json,
        headers: { "destination" => "/topic/registry.adapter.update" }
      )
    end

    before { allow(Sentry).to receive(:capture_exception) }

    it "reports the error to Sentry" do
      call

      expect(Sentry).to have_received(:capture_exception).with(be_a(Importable::WrongMessageError))
    end
  end

  context "when receiving a create catalogue message" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) { create(:jms_json_catalogue) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.catalogue.create" }) }

    it "enqueues an unpublish job for the catalogue" do
      expect { call }
        .to have_enqueued_job(Catalogue::PcCreateOrUpdateJob).with(resource["catalogue"], :unpublished, modified_at)
    end
  end

  context "when receiving an update catalogue message" do
    subject(:call) { described_class.call(message, logger) }

    let(:body) { create(:jms_json_catalogue) }
    let(:resource) { JSON.parse(body)["resource"] }
    let(:modified_at) { Time.zone.at(resource["metadata"]["modifiedAt"].to_i / 1000) }
    let(:message) { double(body: body, headers: { "destination" => "/topic/registry.catalogue.update" }) }

    it "enqueues an unpublish job for the catalogue" do
      expect { call }
        .to have_enqueued_job(Catalogue::PcCreateOrUpdateJob).with(resource["catalogue"], :unpublished, modified_at)
    end
  end
end
