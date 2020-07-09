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
    log body
    resource = @parser.parse(body["resource"])

    raise ResourceParseError.new("Cannot parse resource") if resource.empty?

    case body["resourceType"]
    when "infra_service"
      if resource["infraService"]["latest"]
        Service::PcCreateOrUpdate.new(resource["infraService"]["service"], @eic_base_url, @logger).call
      end
    when "provider"
      if resource["providerBundle"]["active"]
        Provider::PcCreateOrUpdate.new(resource["providerBundle"]["provider"], @logger).call
      end
    else
      log @message
    end
  end

  private
    def log(msg)
      @logger.info(msg)
    end
end
