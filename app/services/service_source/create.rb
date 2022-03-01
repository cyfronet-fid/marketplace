# frozen_string_literal: true

class ServiceSource::Create
  def initialize(service, source_type = "eosc_registry")
    @service = service
    @source_type = source_type
  end

  def call
    new_source =
      ServiceSource.create(
        service_id: @service.id,
        source_type: @source_type,
        eid: @service.pid,
        errored: @service.errors.to_hash
      )
    @service.update(upstream_id: new_source.id)
  end
end
