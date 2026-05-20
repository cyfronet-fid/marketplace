# frozen_string_literal: true

class Provider::PcCreateOrUpdate < ApplicationService
  def initialize(eosc_registry_provider, status, modified_at)
    super()
    @eosc_registry_provider = eosc_registry_provider
    @eid = eosc_registry_provider["id"]
    @status = status
    @modified_at = modified_at
  end

  def call
    provider_hash = Importers::Provider.call(@eosc_registry_provider, @modified_at)
    mapped_provider = find_provider(provider_hash)

    ActiveRecord::Base.transaction do
      if mapped_provider.nil?
        mapped_provider = Provider.new(provider_hash)
        mapped_provider.set_default_logo
      else
        mapped_provider.assign_attributes(provider_hash)
      end

      mapped_provider.status = @status
      mapped_provider.save!

      provider_source = mapped_provider.sources.find_or_create_by!(source_type: "eosc_registry", eid: @eid)
      mapped_provider.update!(upstream_id: provider_source.id)
    end

    Importers::Logo.new(mapped_provider, @eosc_registry_provider["logo"]).call
    mapped_provider.save!
    mapped_provider
  end

  private

  def find_provider(provider_hash)
    Provider.joins(:sources).find_by("provider_sources.source_type": "eosc_registry", "provider_sources.eid": @eid) ||
      Provider.find_by(pid: provider_hash[:pid]) || provider_by_ppid(provider_hash[:ppid])
  end

  def provider_by_ppid(ppid)
    return if ppid.blank?

    Provider.joins(:alternative_identifiers).find_by(alternative_identifiers: { value: ppid })
  end
end
