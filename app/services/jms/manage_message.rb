# frozen_string_literal: true

require "nori"

class Jms::ManageMessage
  class ResourceParseError < StandardError; end

  class WrongMessageError < StandardError; end

  def initialize(message, eosc_registry_base_url, logger, token = nil)
    @parser = Nori.new(strip_namespaces: true)
    @message = message
    @logger = logger
    @eosc_registry_base_url = eosc_registry_base_url
    @token = token
  end

  def call
    body = JSON.parse(@message.body)
    action = @message.headers["destination"].split(".").last
    log body
    resource = @parser.parse(body["resource"])

    raise ResourceParseError.new("Cannot parse resource") if resource.empty?

    case body["resourceType"]
    when "infra_service"
      modified_at = modified_at(resource, "infraService")
      if action != "delete" && resource["infraService"]["latest"]
        Service::PcCreateOrUpdateJob.perform_later(resource["infraService"]["service"],
                                                   @eosc_registry_base_url,
                                                   resource["infraService"]["active"],
                                                   modified_at,
                                                   @token)

      elsif action == "delete"
        Service::DeleteJob.perform_later(resource["infraService"]["service"]["id"])
      end
    when "provider"
      modified_at = modified_at(resource, "providerBundle")
      if resource["providerBundle"]["active"]
        Provider::PcCreateOrUpdateJob.perform_later(resource["providerBundle"]["provider"], modified_at)
      end
    else
      raise WrongMessageError
    end
  rescue WrongMessageError => e
    warn "[WARN] Message arrived, but the type is unknown: #{body["resourceType"]}, #{e}"
    Sentry.capture_exception(e)
  end

  private
    def modified_at(resource, resource_type)
      metadata  = resource[resource_type]["metadata"]
      Time.at(metadata["modifiedAt"].to_i&./1000)
    end

    def log(msg)
      @logger.info(msg)
    end

    def warn(msg)
      @logger.warn(msg)
    end
end
