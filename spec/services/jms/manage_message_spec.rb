# frozen_string_literal: true

require "rails_helper"
require "stomp"
require "nori"

describe Jms::ManageMessage, backend: true do
  let(:eosc_registry_base) { "localhost" }
  let(:logger) { Logger.new($stdout) }
  let(:parser) { Nori.new(strip_namespaces: true) }
  let(:service_resource) { create(:jms_xml_service) }
  let(:provider_resource) { create(:jms_xml_provider) }
  let(:catalogue_resource) { create(:jms_xml_catalogue) }
  let(:draft_provider_resource) { build(:jms_xml_draft_provider) }
  let(:rejected_provider_resource) { build(:jms_xml_rejected_provider) }
  let(:json_service) do
    double(body: service_resource.to_json, headers: { "destination" => "/topic/registry.service.update" })
  end
  let(:json_provider) do
    double(body: provider_resource.to_json, headers: { "destination" => "/topic/registry.provider.update" })
  end
  let(:json_catalogue) do
    double(body: catalogue_resource.to_json, headers: { "destination" => "/topic/registry.catalogue.update" })
  end
  let(:json_create_catalogue) do
    double(body: catalogue_resource.to_json, headers: { "destination" => "/topic/registry.catalogue.create" })
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
      resource["serviceBundle"]["service"],
      eosc_registry_base,
      :published,
      Time.at(resource["serviceBundle"]["metadata"]["modifiedAt"].to_i&./ 1000),
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
      :published,
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
      :published,
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_provider, eosc_registry_base, logger, nil).call }.to_not raise_error

    resource = parser.parse(draft_provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      :unpublished,
      Time.at(resource["providerBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_draft_provider, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update to update rejected provider message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(rejected_provider_resource["resource"])
    expect(Provider::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["providerBundle"]["provider"],
      :unpublished,
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
    expect(Provider::DeleteJob).to receive(:perform_later).with("eosc.cyfronet")

    expect { described_class.new(json_provider, eosc_registry_base, logger).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive service delete message" do
    service = create(:service)
    create(:service_source, service: service, eid: "eosc.tp.openminted_catalogue_of_corpora_2")
    original_stdout = $stdout
    $stdout = StringIO.new
    json_service =
      double(body: service_resource.to_json, headers: { "destination" => "/topic/registry.service.delete" })
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
    $stdout = StringIO.new
    resource = parser.parse(catalogue_resource["resource"])
    expect(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["catalogueBundle"]["catalogue"],
      :published,
      Time.at(resource["catalogueBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_create_catalogue, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end

  it "should receive update catalogue message" do
    original_stdout = $stdout
    $stdout = StringIO.new
    resource = parser.parse(catalogue_resource["resource"])
    expect(Catalogue::PcCreateOrUpdateJob).to receive(:perform_later).with(
      resource["catalogueBundle"]["catalogue"],
      :published,
      Time.at(resource["catalogueBundle"]["metadata"]["modifiedAt"].to_i&./ 1000)
    )

    expect { described_class.new(json_catalogue, eosc_registry_base, logger, nil).call }.to_not raise_error
    $stdout = original_stdout
  end
end
