# frozen_string_literal: true

require "rails_helper"
require "stomp"
require "nori"

describe Jms::ManageMessage do
  let(:eosc_registry_base) { "localhost" }
  let(:logger) { Logger.new($stdout) }
  let(:parser) { Nori.new(strip_namespaces: true) }
  let(:service_resource) { create(:jms_xml_service) }
  let(:provider_resource) { create(:jms_xml_provider) }
  let(:draft_provider_resource) { build(:jms_xml_draft_provider) }
  let(:rejected_provider_resource) { build(:jms_xml_rejected_provider) }
  let(:json_service) do
    double(body: service_resource.to_json, headers: { "destination" => "/topic/registry.infra_service.update" })
  end
  let(:json_provider) do
    double(body: provider_resource.to_json, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:json_draft_provider) do
    double(body: draft_provider_resource.to_json, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:json_rejected_provider) do
    double(body: rejected_provider_resource.to_json, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:service_create_or_update) { instance_double(Service::PcCreateOrUpdate) }
  let(:provider_create_or_update) { instance_double(Provider::PcCreateOrUpdate) }

  it "should receive service message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(service_resource["resource"])
    expect(Service::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["infraService"]["service"],
      eosc_registry_base,
      true,
      Time.at(resource["infraService"]["metadata"]["modifiedAt"].to_i&./ 1000),
      nil
    )
    expect { described_class.new(json_service, eosc_registry_base, logger).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update active provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      resource["providerBundle"]["active"],
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update to draft provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      resource["providerBundle"]["active"],
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_provider, eosc_registry_base, logger, nil).call }.to_not raise_error

    resource = parser.parse(draft_provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      resource["providerBundle"]["active"],
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_draft_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should do nothing for update rejected provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(rejected_provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to_not receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      resource["providerBundle"]["active"],
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_rejected_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive provider delete message" do
    provider = create(:provider)
    create(:provider_source, provider: provider, eid: "cyfronet")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_provider =
      double(body: provider_resource.to_json, headers: { "destination" => "/topic/registry.provider.delete" })
    expect(Provider::DeleteJob).to receive(:perform_later).with("cyfronet")

    expect { described_class.new(json_provider, eosc_registry_base, logger).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive service delete message" do
    service = create(:service)
    create(:service_source, service: service, eid: "tp.openminted_catalogue_of_corpora_2")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_service =
      double(body: service_resource.to_json, headers: { "destination" => "/topic/registry.infra_service.delete" })
    expect(Service::DeleteJob).to receive(:perform_later).with("tp.openminted_catalogue_of_corpora_2")

    expect { described_class.new(json_service, eosc_registry_base, logger).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive error if message is invalid" do
    original_stdout = $stdout
    $stdout = StringIO.new
    service_hash = { some_happy_key: "some_happy_value" }
    error_service_message = double(body: service_hash.to_json, headers: { "destination" => "aaaa.update" })

    expect { described_class.new(error_service_message, eosc_registry_base, logger).call }.to raise_error(StandardError)
    $stdout = original_stdout
  end
end
