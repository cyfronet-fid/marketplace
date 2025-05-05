# frozen_string_literal: true

require "rails_helper"
require "stomp"

describe Jms::ManageMessage, backend: true do
  let(:eosc_registry_base) { "localhost" }
  let(:logger) { Logger.new($stdout) }
  let(:parser) { JSON }
  let(:service_resource) { create(:jms_json_service) }
  let(:provider_resource) { create(:jms_json_provider) }
  let(:catalogue_resource) { create(:jms_json_catalogue) }
  let(:draft_provider_resource) { build(:jms_json_draft_provider) }
  let(:rejected_provider_resource) { build(:jms_json_rejected_provider) }
  let(:json_service) { double(body: service_resource, headers: { "destination" => "/topic/registry.service.update" }) }
  let(:json_provider) do
    double(body: provider_resource, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:json_catalogue) do
    double(body: catalogue_resource, headers: { "destination" => "/topic/registry.catalogue.update" })
  end
  let(:json_create_catalogue) do
    double(body: catalogue_resource, headers: { "destination" => "/topic/registry.catalogue.create" })
  end
  let(:json_draft_provider) do
    double(body: draft_provider_resource, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:json_rejected_provider) do
    double(body: rejected_provider_resource, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:service_create_or_update) { instance_double(Service::PcCreateOrUpdate) }
  let(:provider_create_or_update) { instance_double(Provider::PcCreateOrUpdate) }

  it "should receive service message" do
    response = parser.parse(service_resource)
    resource = response["resource"]
    original_stdout = $stdout

    $stdout = StringIO.new

    expect(Service::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["service"],
      eosc_registry_base,
      :published,
      Time.at(resource["metadata"]["modifiedAt"].to_i&./ 1000),
      nil
    )
    expect { described_class.call(json_service, eosc_registry_base, logger) }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update active provider message" do
    original_stdout = $stdout

    $stdout = StringIO.new
    response = parser.parse(provider_resource)
    resource = response["resource"]

    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["provider"],
      :published,
      Time.at(resource["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.call(json_provider, eosc_registry_base, logger, nil) }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update to draft provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    response = parser.parse(provider_resource)
    resource = response["resource"]
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["provider"],
      :published,
      Time.at(resource["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_provider, eosc_registry_base, logger, nil).call }.to_not raise_error

    response = parser.parse(draft_provider_resource)
    resource = response["resource"]
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["provider"],
      :unpublished,
      Time.at(resource["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_draft_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update to update rejected provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    response = parser.parse(rejected_provider_resource)
    resource = response["resource"]
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["provider"],
      :unpublished,
      Time.at(resource["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_rejected_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive provider delete message" do
    provider = create(:provider)
    create(:provider_source, provider: provider, eid: "cyfronet")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_provider = double(body: provider_resource, headers: { "destination" => "/topic/registry.provider.delete" })
    expect(Provider::DeleteJob).to receive(:perform_later).with("eosc.cyfronet")

    expect { described_class.new(json_provider, eosc_registry_base, logger).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive service delete message" do
    service = create(:service)
    create(:service_source, service: service, eid: "eosc.tp.openminted_catalogue_of_corpora_2")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_service = double(body: service_resource, headers: { "destination" => "/topic/registry.service.delete" })
    expect(Service::DeleteJob).to receive(:perform_later).with("eosc.tp.openminted_catalogue_of_corpora_2")

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

  it "should receive create catalogue message" do
    original_stdout = $stdout
    # $stdout = StringIO.new
    response = JSON.parse(catalogue_resource)
    resource = response["resource"]
    expect(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["catalogue"],
      :published,
      Time.at(resource["metadata"]["modifiedAt"].to_i / 1000)
    )

    expect { described_class.call(json_create_catalogue, eosc_registry_base, logger, nil) }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update catalogue message" do
    original_stdout = $stdout
    # $stdout = StringIO.new
    response = parser.parse(catalogue_resource)
    resource = response["resource"]
    expect(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["catalogue"],
      :published,
      Time.at(resource["metadata"]["modifiedAt"].to_i / 1000)
    )

    expect { described_class.call(json_catalogue, eosc_registry_base, logger, nil) }.to_not raise_error
    $stdout = original_stdout
  end
end
