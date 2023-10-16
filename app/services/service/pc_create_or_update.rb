# frozen_string_literal: true

require "mini_magick"

class Service::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_service, eosc_registry_base_url, is_active, modified_at, token)
    @error_message = "Service haven't been updated. Message #{eosc_registry_service}"
    @logo = eosc_registry_service["logo"]
    @is_active = is_active
    @source_type = "eosc_registry"
    @original_id = eosc_registry_service["originalId"]
    @mp_service =
      Service
        .joins(:sources)
        .find_by(
          "service_sources.source_type": @source_type,
          "service_sources.eid": [@original_id, eosc_registry_service["id"]]
        )
    eosc_registry_service["status"] = @is_active ? "published" : "draft"
    @service_hash = Importers::Service.new(eosc_registry_service, modified_at, eosc_registry_base_url, token).call
    @new_update_available = Service::PcCreateOrUpdate.new_update_available(@mp_service, modified_at)
  end

  def call
    create_new = @mp_service.nil? && @is_active
    return Service::PcCreateOrUpdate.create_service(@service_hash, @logo) if create_new
    return @mp_service unless @new_update_available

    source = @mp_service&.sources&.find_by(source_type: @source_type)
    can_update = @mp_service.present? && (@is_active || source.present?)
    unless can_update
      Service::PcCreateOrUpdate.handle_invalid_data(@mp_service, @service_hash, @error_message)
      return @mp_service
    end
    update_valid = Service::Update.call(@mp_service, @service_hash)
    source.update(eid: @service_hash["pid"])
    unless update_valid
      Service::PcCreateOrUpdate.handle_invalid_data(@mp_service, @service_hash, @error_message)
      return @mp_service
    end

    if source.present?
      @mp_service.update(upstream_id: source.id)
      @mp_service.sources.first.update(errored: nil)
    end

    Importers::Logo.new(@mp_service, @logo).call
    @mp_service.save!
    @mp_service
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(service, modified_at)
    return true unless service&.synchronized_at.present?
    modified_at >= service.synchronized_at
  end

  def self.handle_invalid_data(mp_service, service_hash, error_message)
    Rails.logger.warn error_message
    validatable_service = Service.new(service_hash)
    service_errors = validatable_service&.errors&.to_hash if validatable_service.invalid?
    mp_service&.sources&.first&.update(eid: service_hash["pid"], errored: service_errors)
  end

  def self.create_service(service_hash, logo)
    service = Service.new(service_hash)
    if service.valid?
      Service::Create.call(service)
    else
      service.status = "errored"
      service.save(validate: false)
    end
    ServiceSource::Create.call(service)

    Importers::Logo.call(service, logo)
    service.save!(validate: false)
    service
  end
end
