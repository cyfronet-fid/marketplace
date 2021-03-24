# frozen_string_literal: true

require "mini_magick"

class Service::PcCreateOrUpdate
  class ConnectionError < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  class NotUpdatedError < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  def initialize(eic_service,
                 eic_base_url,
                 is_active,
                 modified_at,
                 token,
                 unirest: Unirest)
    @unirest = unirest
    @eic_base_url = eic_base_url
    @eid = eic_service["id"]
    @eic_service =  eic_service
    @is_active = is_active
    @token = token
    @modified_at = modified_at
  end

  def call
    service_hash = Importers::Service.new(@eic_service, @modified_at, @eic_base_url, @token).call
    mapped_service = Service.joins(:sources).find_by("service_sources.source_type": "eic",
                                                     "service_sources.eid": @eid)
    source_id = mapped_service.nil? ? nil : mapped_service.sources.find_by(source_type: "eic")

    is_newer_update = mapped_service&.synchronized_at.present? ? (@modified_at >= mapped_service.synchronized_at) : true

    if mapped_service.nil? && @is_active
      service = Service.new(service_hash)
      Importers::Logo.new(service, @eic_service["logo"]).call
      if service.valid?
        Service::Create.new(service).call
      else
        service.status = "errored"
        service.save(validate: false)
      end
      source = ServiceSource.create!(service_id: service.id, source_type: "eic", eid: @eid,
                                     errored: service.errors.messages)
      service.update(upstream_id: source.id)
      service
    elsif is_newer_update
      if mapped_service && !@is_active
        Importers::Logo.new(mapped_service, @eic_service["logo"]).call
        Service::Update.new(mapped_service, service_hash).call
        Service::Draft.new(mapped_service).call
        mapped_service
      elsif !source_id.nil?
        if check_service = Service.new(service_hash).invalid?
          raise NotUpdatedError.new("Service is not updated, because parsed service data is invalid")
        end
        Importers::Logo.new(mapped_service, @eic_service["logo"]).call
        Service::Update.new(mapped_service, service_hash).call
        mapped_service.update(upstream_id: source_id.id)
        mapped_service.sources.first.update(errored: nil)
        mapped_service
      else
        raise NotUpdatedError.new("Service source_id is unrecognized.")
      end
    else
      raise NotUpdatedError.new("Service is not updated because there is a newer version imported.")
    end
  rescue NotUpdatedError => e
    Rails.logger.warn "#{e} Message arrived, but service is not updated. Message #{@eic_service}"
    if mapped_service.present? && mapped_service&.sources&.first.present?
      source = mapped_service&.sources&.first
      source.update(errored: check_service.errors.messages)
    end
    mapped_service
  rescue Errno::ECONNREFUSED
    raise ConnectionError.new("[WARN] Connection refused.")
  end
end
