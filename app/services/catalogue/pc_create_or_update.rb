# frozen_string_literal: true

class Catalogue::PcCreateOrUpdate
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_catalogue, is_active, modified_at)
    @error_message = "Catalogue haven't been updated. Message #{eosc_registry_catalogue}"
    @is_active = is_active
    @source_type = "eosc_registry"
    @mp_catalogue = Catalogue.find_by(pid: eosc_registry_catalogue["id"])
    @catalogue_hash = Importers::Catalogue.new(eosc_registry_catalogue, modified_at).call
    @new_update_available = Catalogue::PcCreateOrUpdate.new_update_available(@mp_catalogue, modified_at)
  end

  def call
    create_new = @mp_catalogue.nil? && @is_active
    return Catalogue::PcCreateOrUpdate.create_catalogue(@catalogue_hash) if create_new
    return @mp_catalogue unless @new_update_available

    Catalogue::PcCreateOrUpdate.update_catalogue(@mp_catalogue, @catalogue_hash)
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(catalogue, modified_at)
    return true unless catalogue&.synchronized_at.present?
    modified_at >= catalogue.synchronized_at
  end

  def self.create_catalogue(catalogue_hash)
    catalogue = Catalogue.new(catalogue_hash)
    catalogue.save!
  end

  def self.update_catalogue(catalogue, catalogue_hash)
    catalogue.update(catalogue_hash)
    catalogue.save!
  end
end
