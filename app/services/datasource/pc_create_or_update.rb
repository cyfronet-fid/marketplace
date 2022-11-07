# frozen_string_literal: true

require "mini_magick"

class Datasource::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_datasource, eosc_registry_base_url, is_active, modified_at, token)
    @error_message = "Datasource haven't been updated. Message #{eosc_registry_datasource}"
    @logo = eosc_registry_datasource["logo"]
    @is_active = is_active
    @source_type = "eosc_registry"
    @mp_datasource =
      Datasource
        .joins(:sources)
        .find_by(
          "datasource_sources.source_type": @source_type,
          "datasource_sources.eid": eosc_registry_datasource["id"]
        )
    @datasource_hash = Importers::Datasource.call(eosc_registry_datasource, modified_at, eosc_registry_base_url, token)
    @new_update_available = Datasource::PcCreateOrUpdate.new_update_available(@mp_datasource, modified_at)
  end

  def call
    create_new = @mp_datasource.nil? && @is_active
    return Datasource::PcCreateOrUpdate.create_datasource(@datasource_hash, @logo) if create_new
    return @mp_datasource unless @new_update_available

    source_id = @mp_datasource&.sources&.find_by(source_type: @source_type)
    can_update = @mp_datasource.present? && (@is_active || source_id.present?)
    unless can_update
      Datasource::PcCreateOrUpdate.handle_invalid_data(@mp_datasource, @datasource_hash, @error_message)
      return @mp_datasource
    end

    update_valid = Datasource::Update.call(@mp_datasource, @datasource_hash)
    unless update_valid
      Datasource::PcCreateOrUpdate.handle_invalid_data(@mp_datasource, @datasource_hash, @error_message)
      return @mp_datasource
    end

    Datasource::Draft.call(@mp_datasource) unless @is_active
    if source_id.present?
      @mp_datasource.update(upstream_id: source_id.id)
      @mp_datasource.sources.first.update(errored: nil)
    end

    Importers::Logo.new(@mp_datasource, @logo).call
    @mp_datasource.save!
    @mp_datasource
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(datasource, modified_at)
    return true unless datasource&.synchronized_at.present? && modified_at.present?
    modified_at >= datasource.synchronized_at
  end

  def self.handle_invalid_data(mp_datasource, datasource_hash, error_message)
    Rails.logger.warn error_message
    validatable_datasource = Datasource.new(datasource_hash)
    datasource_errors = validatable_datasource&.errors&.to_hash if validatable_datasource.invalid?
    mp_datasource&.sources&.first&.update(errored: datasource_errors)
  end

  def self.create_datasource(datasource_hash, logo)
    datasource = Datasource.new(datasource_hash)
    if datasource.valid?
      Datasource::Create.call(datasource)
    else
      datasource.status = "errored"
      datasource.save(validate: false)
    end
    DatasourceSource::Create.call(datasource)

    Importers::Logo.call(datasource, logo)
    datasource.save!(validate: false)
    datasource
  end
end
