# frozen_string_literal: true

require "nori"

class Jms::ManageMessage < ApplicationService
  class ResourceParseError < StandardError
  end

  class WrongMessageError < StandardError
  end

  class WrongIdError < StandardError
  end

  def initialize(message, eosc_registry_base_url, logger, token = nil)
    super()
    @parser = Nori.new(strip_namespaces: true)
    @message = message
    @logger = logger
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity:

  def call
    log @message
    body = JSON.parse(@message.body)
    resource_type = @message.headers["destination"].split(".")[-2]
    action = @message.headers["destination"].split(".").last
    resource = @parser.parse(body["resource"])

    raise ResourceParseError, "Cannot parse resource" if resource.empty?

    case resource_type
    when "service", "infra_service"
      modified_at = modified_at(resource, "serviceBundle")
      if resource["serviceBundle"]["service"]["id"].split(".").size != 3
        raise WrongIdError, resource["serviceBundle"]["service"]["id"]
      end
      if action != "delete" && resource["serviceBundle"]["service"]
        Service::PcCreateOrUpdateJob.perform_later(
          resource["serviceBundle"]["service"],
          @eosc_registry_base_url,
          resource["serviceBundle"]["active"] && !resource["serviceBundle"]["suspended"],
          modified_at,
          @token
        )
      elsif action == "delete"
        Service::DeleteJob.perform_later(resource["serviceBundle"]["service"]["id"])
      end
    when "provider"
      modified_at = modified_at(resource, "providerBundle")
      if resource["providerBundle"]["provider"]["id"].split(".").size != 2
        raise WrongIdError, resource["providerBundle"]["provider"]["id"]
      end
      case action
      when "delete"
        Provider::DeleteJob.perform_later(resource["providerBundle"]["provider"]["id"])
      when "update", "create"
        Provider::PcCreateOrUpdateJob.perform_later(
          resource["providerBundle"]["provider"],
          resource["providerBundle"]["active"] && !resource["providerBundle"]["suspended"],
          modified_at
        )
      end
    when "catalogue"
      modified_at = modified_at(resource, "catalogueBundle")
      case action
      when "update", "create"
        Catalogue::PcCreateOrUpdateJob.perform_later(
          resource["catalogueBundle"]["catalogue"],
          resource["catalogueBundle"]["active"] && !resource["catalogueBundle"]["suspended"],
          modified_at
        )
      end
    when "datasource"
      modified_at = modified_at(resource, "datasourceBundle")
      if resource["datasourceBundle"]["datasource"]["id"].split(".").size != 3
        raise WrongIdError, resource["datasourceBundle"]["datasource"]["id"]
      end
      case action
      when "delete"
        Service::DeleteJob.perform_later(resource["datasourceBundle"]["datasource"]["id"])
      when "update", "create"
        Datasource::PcCreateOrUpdateJob.perform_later(
          resource["datasourceBundle"]["datasource"],
          resource["datasourceBundle"]["active"] && !resource["datasourceBundle"]["suspended"],
          @eosc_registry_base_url,
          @token,
          modified_at
        )
      end
    else
      raise WrongMessageError
    end
  rescue WrongMessageError => e
    warn "[WARN] Message arrived, but the type is unknown: #{body["resourceType"]}, #{e}"
    Sentry.capture_exception(e)
  rescue WrongIdError => e
    warn "[WARN] eid #{e} for #{resource_type} has a wrong format - update disabled"
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity:

  private

  def modified_at(resource, resource_type)
    metadata = resource[resource_type]["metadata"]
    Time.at(metadata["modifiedAt"].to_i&./ 1000)
  end

  def log(msg)
    @logger.info(msg)
  end

  def warn(msg)
    @logger.warn(msg)
  end
end
