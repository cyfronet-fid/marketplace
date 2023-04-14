# frozen_string_literal: true

class DatasourceSource::Create < ApplicationService
  def initialize(datasource, source_type = "eosc_registry")
    super()
    @datasource = datasource
    @source_type = source_type
  end

  def call
    new_source =
      ServiceSource.create(
        service_id: @datasource.id,
        source_type: @source_type,
        eid: @datasource.pid,
        errored: @datasource.errors.to_hash
      )
    @datasource.update(upstream_id: new_source.id)
  end
end
