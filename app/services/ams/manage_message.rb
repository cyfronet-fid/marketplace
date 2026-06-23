# frozen_string_literal: true

class Ams::ManageMessage < ApplicationService
  include Importable

  INBOUND_TOPIC_ALIASES = {
    "organisation" => "provider",
    "deployable_application" => "deployable_service",
    "interoperability_record" => "guideline"
  }.freeze

  def initialize(message, topic, eosc_registry_base_url = nil, logger = nil, token = nil)
    super()
    @message = message
    @topic = topic
    @eosc_registry_base_url = eosc_registry_base_url
    @logger = logger
    @token = token
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def call
    log @message
    body = JSON.parse(@message)

    # Topic pattern: mp-${model}-${action}
    # destination is expected to be prefix.model.action
    destination_parts = @topic.split(/[-.]/)
    raw_type = destination_parts[-2]
    resource_type = INBOUND_TOPIC_ALIASES.fetch(raw_type, raw_type)
    action = destination_parts.last
    event_body = body["resource"] || body

    resource = event_body[raw_type.camelize(:lower)] || event_body[resource_type.camelize(:lower)]

    raise ResourceParseError, "Cannot parse resource: #{resource_type}" if resource.nil? || resource.empty?

    case resource_type
    when "service", "infra_service"
      modified_at = modified_at(event_body)
      case action
      when "delete"
        Service::DeleteJob.perform_later(resource["id"])
      else
        Service::PcCreateOrUpdateJob.perform_later(
          resource,
          @eosc_registry_base_url,
          object_status(event_body["active"], event_body["suspended"]),
          modified_at,
          @token
        )
      end
    when "provider"
      modified_at = modified_at(event_body)
      case action
      when "delete"
        Provider::DeleteJob.perform_later(resource["id"])
      when "update", "create"
        Provider::PcCreateOrUpdateJob.perform_later(
          resource,
          object_status(event_body["active"], event_body["suspended"]),
          modified_at
        )
      end
    when "catalogue"
      modified_at = modified_at(event_body)
      case action
      when "update", "create"
        Catalogue::PcCreateOrUpdateJob.perform_later(
          resource,
          object_status(event_body["active"], event_body["suspended"]),
          modified_at
        )
      end
    when "datasource"
      hash = resource.to_hash

      case action
      when "delete"
        Datasource::DeleteJob.perform_later(hash["id"])
      else
        Datasource::PcCreateOrUpdateJob.perform_later(
          hash,
          object_status(event_body["active"], event_body["suspended"])
        )
      end
    when "deployable_service"
      hash = resource.to_hash

      case action
      when "delete"
        DeployableService::DeleteJob.perform_later(hash["id"])
      else
        DeployableService::PcCreateOrUpdateJob.perform_later(
          hash,
          object_status(event_body["active"], event_body["suspended"])
        )
      end
    when "guideline"
      modified_at = modified_at(event_body)
      case action
      when "delete"
        Guideline::DeleteJob.perform_later(resource["id"])
      else
        Guideline::PcCreateOrUpdateJob.perform_later(
          resource,
          object_status(event_body["active"], event_body["suspended"]),
          modified_at
        )
      end
    else
      raise WrongMessageError
    end
  rescue WrongMessageError => e
    warn "[WARN] Message arrived, but the type is unknown: #{resource_type}, #{e}"
    Sentry.capture_exception(e)
  rescue WrongIdError => e
    warn "[WARN] eid #{e} for #{resource_type} has a wrong format - update disabled"
  rescue ResourceParseError => e
    warn "[WARN] Resource parse error: #{e.message}"
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize

  private

  def modified_at(body)
    m = body.dig("metadata", "modifiedAt")
    m ? Time.at(m.to_i / 1000) : Time.now # V6 keeps Unix ms; ISO 8601 applies to entity fields only.
  end

  def log(message)
    @logger&.info message
  end

  def warn(message)
    @logger&.warn message
  end
end
