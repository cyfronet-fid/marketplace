# frozen_string_literal: true

class Jms::ManageMessage < ApplicationService
  include Importable

  def initialize(message, eosc_registry_base_url, logger, token = nil)
    super()
    @message = message
    @logger = logger
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
    Sidekiq.strict_args! false
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def call
    log @message
    body = JSON.parse(@message.body)
    resource_type = @message.headers["destination"].split(".")[-2]
    action = @message.headers["destination"].split(".").last
    resource = body[resource_type.camelize(:lower)]

    raise Importable::ResourceParseError, "Cannot parse resource" if resource.nil? || resource.empty?

    case resource_type
    when "service", "infra_service"
      modified_at = modified_at(body)
      if action != "delete"
        Service::PcCreateOrUpdateJob.perform_later(
          resource,
          @eosc_registry_base_url,
          object_status(body["active"], body["suspended"]),
          modified_at,
          @token
        )
      elsif action == "delete"
        Service::DeleteJob.perform_later(resource["id"])
      end
    when "provider"
      modified_at = modified_at(body)
      case action
      when "delete"
        Provider::DeleteJob.perform_later(resource["id"])
      when "update", "create"
        Provider::PcCreateOrUpdateJob.perform_later(
          resource,
          object_status(body["active"], body["suspended"]),
          modified_at
        )
      end
    when "catalogue"
      modified_at = modified_at(body)
      case action
      when "update", "create"
        Catalogue::PcCreateOrUpdateJob.perform_later(
          resource,
          object_status(body["active"], body["suspended"]),
          modified_at
        )
      end
    when "datasource"
      hash = resource.to_hash

      if action != "delete"
        Datasource::PcCreateOrUpdateJob.perform_later(hash, object_status(body["active"], body["suspended"]))
      elsif action == "delete"
        Datasource::DeleteJob.perform_later(hash["id"])
      end
    when "deployable_service"
      hash = resource.to_hash

      if action != "delete"
        DeployableService::PcCreateOrUpdateJob.perform_later(hash, object_status(body["active"], body["suspended"]))
      elsif action == "delete"
        DeployableService::DeleteJob.perform_later(hash["id"])
      end
    else
      raise Importable::WrongMessageError
    end
  rescue Importable::WrongMessageError => e
    warn "[WARN] Message arrived, but the type is unknown: #{resource_type}, #{e}"
    Sentry.capture_exception(e)
  rescue Importable::WrongIdError => e
    warn "[WARN] eid #{e} for #{resource_type} has a wrong format - update disabled"
  rescue Importable::ResourceParseError => e
    warn "[WARN] Resource parse error: #{e.message}"
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

  private

  def modified_at(resource)
    metadata = resource["metadata"]
    Time.at(metadata["modifiedAt"].to_i / 1000)
  end

  def resource_extras(resource)
    resource.key?("resourceExtras") ? resource["resourceExtras"] : {}
  end

  def log(msg)
    @logger.info(msg)
  end

  def warn(msg)
    @logger.warn(msg)
  end
end
