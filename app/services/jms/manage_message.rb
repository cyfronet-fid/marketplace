# frozen_string_literal: true

class Jms::ManageMessage < ApplicationService
  include Importable

  class ResourceParseError < StandardError
  end

  class WrongMessageError < StandardError
  end

  class WrongIdError < StandardError
  end

  def initialize(message, eosc_registry_base_url, logger, token = nil)
    super()
    @message = message
    @logger = logger
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
    Sidekiq.strict_args! false
  end

  def call
    log @message
    body = JSON.parse(@message.body)
    resource_type = @message.headers["destination"].split(".")[-2]
    action = @message.headers["destination"].split(".").last
    resource = body[resource_type]

    raise ResourceParseError, "Cannot parse resource" if resource.nil? || resource.empty?

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

  private

  def modified_at(resource)
    metadata = resource["metadata"]
    Time.at(metadata["modifiedAt"].to_i&./ 1000)
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
