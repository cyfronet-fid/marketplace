# frozen_string_literal: true

class Catalogue::PcCreateOrUpdate < ApplicationService
  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(eosc_registry_catalogue, status, modified_at)
    super()
    @error_message = "Catalogue haven't been updated. Message #{eosc_registry_catalogue}"
    @status = status
    @source_type = "eosc_registry"
    @mp_catalogue = Catalogue.find_by(pid: eosc_registry_catalogue["id"])
    @catalogue_hash = Importers::Catalogue.new(eosc_registry_catalogue, modified_at).call
    @catalogue_hash[:status] = @status
    @new_update_available = Catalogue::PcCreateOrUpdate.new_update_available(@mp_catalogue, modified_at)
    @logo = eosc_registry_catalogue["logo"]
  end

  def call
    create_new = @mp_catalogue.nil? && @status == :published
    return Catalogue::PcCreateOrUpdate.create_catalogue(@catalogue_hash, @logo, @source_type) if create_new
    return @mp_catalogue unless @new_update_available

    Catalogue::PcCreateOrUpdate.update_catalogue(@mp_catalogue, @catalogue_hash, @logo, @source_type)
  rescue Errno::ECONNREFUSED
    raise ConnectionError, "[WARN] Connection refused."
  end

  def self.new_update_available(catalogue, modified_at)
    return false if catalogue.blank?
    return true unless catalogue&.synchronized_at.present?
    modified_at >= catalogue.synchronized_at
  end

  def self.create_catalogue(catalogue_hash, logo, source_type)
    catalogue = Catalogue.new(catalogue_hash)
    set_logo(catalogue, logo)

    if catalogue.save!
      CatalogueSource.create_or_find_by!(catalogue_id: catalogue.id, source_type: source_type, eid: catalogue.pid)
    end
    catalogue
  end

  def self.update_catalogue(catalogue, catalogue_hash, logo, source_type)
    catalogue.assign_attributes(catalogue_hash)
    set_logo(catalogue, logo)

    if catalogue.save! && catalogue.upstream_id.blank?
      CatalogueSource.create_or_find_by!(catalogue_id: catalogue.id, source_type: source_type, eid: catalogue.pid)
    end

    catalogue
  end

  def self.set_logo(catalogue, logo)
    # Assign a default logo if there are some problems in the mapper later
    catalogue.set_default_logo
    Importers::Logo.new(catalogue, logo).call
  end
end
