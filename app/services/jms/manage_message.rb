# frozen_string_literal: true

require "nori"

class Jms::ManageMessage
  def initialize(message, eic_base_url, logger)
    @parser = Nori.new(strip_namespaces: true)
    @message = message
    @logger = logger
    @eic_base_url = eic_base_url
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
                                                   @eic_base_url,
                                                   resource["infraService"]["active"],
                                                   modified_at)

      elsif action == "delete"
        Service::DeleteJob.perform_later(resource["infraService"]["service"]["id"])
      end
    when "provider"
      if resource["providerBundle"]["active"]
        Provider::PcCreateOrUpdateJob.perform_later(resource["providerBundle"]["provider"])
      end
    else
      log @message
    end
  end

  private
    def modified_at(resource, resource_type)
      metadata  = resource[resource_type]["metadata"]
      Time.new(metadata["modifiedAt"])
    end

    def log(msg)
      @logger.info(msg)
    end
end
