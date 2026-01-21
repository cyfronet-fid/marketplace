# frozen_string_literal: true

require "image_processing/vips"

class DeployableService::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_deployable_service, is_active)
    @error_message = "Deployable Service haven't been updated. Message #{eosc_registry_deployable_service}"
    @source_type = "eosc_registry"
    @is_active = is_active
    @mp_deployable_service =
      DeployableService.joins(:sources).find_by(
        "deployable_service_sources.source_type": @source_type,
        "deployable_service_sources.eid": eosc_registry_deployable_service["id"]
      )
    @deployable_service_hash =
      Importers::DeployableService.call(eosc_registry_deployable_service, Time.current, nil, nil)
    @deployable_service_hash["status"] = @is_active ? "published" : "draft"

    @new_update_available = true
  end

  def call
    create_new = @mp_deployable_service.nil?
    return DeployableService::PcCreateOrUpdate.create_deployable_service(@deployable_service_hash) if create_new
    return @mp_deployable_service unless @new_update_available

    source_id = @mp_deployable_service&.sources&.find_by(source_type: @source_type)
    can_update = @mp_deployable_service.present? && source_id.present?
    unless can_update
      DeployableService::PcCreateOrUpdate.handle_invalid_data(
        @mp_deployable_service,
        @deployable_service_hash,
        @error_message
      )
      return @mp_deployable_service
    end

    update_valid = DeployableService::Update.call(@mp_deployable_service, @deployable_service_hash)
    unless update_valid
      DeployableService::PcCreateOrUpdate.handle_invalid_data(
        @mp_deployable_service,
        @deployable_service_hash,
        @error_message
      )
      return @mp_deployable_service
    end

    if source_id.present?
      @mp_deployable_service.update(upstream_id: source_id.id)
      @mp_deployable_service.sources.first.update(errored: nil)
    end

    @mp_deployable_service.save!
    @mp_deployable_service
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(deployable_service, modified_at)
    return true unless deployable_service&.synchronized_at.present? && modified_at.present?
    modified_at >= deployable_service.synchronized_at
  end

  def self.handle_invalid_data(mp_deployable_service, deployable_service_hash, error_message)
    Rails.logger.warn error_message
    validatable_deployable_service = DeployableService.new(deployable_service_hash)
    if validatable_deployable_service.invalid?
      deployable_service_errors = validatable_deployable_service&.errors&.to_hash
    end
    mp_deployable_service.sources&.first&.update(errored: deployable_service_errors)
  end

  def self.create_deployable_service(deployable_service_hash)
    deployable_service = DeployableService.new(deployable_service_hash)
    if deployable_service.valid?
      DeployableService::Create.call(deployable_service)
    else
      deployable_service.status = "errored"
      deployable_service.save(validate: false)
    end
    DeployableServiceSource::Create.call(deployable_service)

    deployable_service
  end
end
