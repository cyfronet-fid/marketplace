# frozen_string_literal: true

require "mini_magick"

class Service::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_service,
                 eosc_registry_base_url,
                 is_active,
                 modified_at,
                 token,
                 faraday: Faraday)
    @faraday = faraday
    @eosc_registry_base_url = eosc_registry_base_url
    @eid = eosc_registry_service["id"]
    @eosc_registry_service = eosc_registry_service
    @is_active = is_active
    @token = token
    @modified_at = modified_at
  end

  def call
    service_hash = Importers::Service.new(@eosc_registry_service, @modified_at, @eosc_registry_base_url, @token).call
    mapped_service = Service.joins(:sources).find_by("service_sources.source_type": "eosc_registry",
                                                     "service_sources.eid": @eid)
    source_id = mapped_service.nil? ? nil : mapped_service.sources.find_by(source_type: "eosc_registry")

    is_newer_update = mapped_service&.synchronized_at.present? ? (@modified_at >= mapped_service.synchronized_at) : true

    if mapped_service.nil? && @is_active
      service = Service.new(service_hash)
      if service.valid?
        Service::Create.new(service).call
      else
        service.status = "errored"
        service.save(validate: false)
      end
      source = ServiceSource.create!(service_id: service.id, source_type: "eosc_registry", eid: @eid,
                                     errored: service.errors.to_hash)
      service.update(upstream_id: source.id)

      Importers::Logo.new(service, @eosc_registry_service["logo"]).call
      service.save!(validate: false)
      service
    elsif is_newer_update
      if mapped_service && !@is_active
        Service::Update.new(mapped_service, service_hash).call
        Service::Draft.new(mapped_service).call

        Importers::Logo.new(mapped_service, @eosc_registry_service["logo"]).call
        mapped_service.save!
        mapped_service
      elsif !source_id.nil?
        checked_service = Service.new(service_hash)
        if checked_service.invalid?
          raise NotUpdatedError, "Service is not updated, because parsed service data is invalid"
        end

        Service::Update.new(mapped_service, service_hash).call
        mapped_service.update(upstream_id: source_id.id)
        mapped_service.sources.first.update(errored: nil)

        Importers::Logo.new(mapped_service, @eosc_registry_service["logo"]).call
        mapped_service.save!
        mapped_service
      else
        raise NotUpdatedError, "Service source_id is unrecognized."
      end
    else
      raise NotUpdatedError, "Service is not updated because there is a newer version imported."
    end
  rescue NotUpdatedError => e
    Rails.logger.warn "#{e} Message arrived, but service is not updated. Message #{@eosc_registry_service}"
    if mapped_service.present? && mapped_service&.sources&.first.present?
      source = mapped_service&.sources&.first
      source.update(errored: checked_service&.errors&.to_hash)
    end
    mapped_service
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end
end
