# frozen_string_literal: true

require "mini_magick"

class Import::Providers
  def initialize(eic_base_url,
                 dry_run: true,
                 filepath: nil,
                 unirest: Unirest,
                 logger: ->(msg) { puts msg },
                 ids: [],
                 default_upstream: :mp,
                 token: nil)
    @eic_base_url = eic_base_url
    @dry_run = dry_run
    @unirest = unirest
    @default_upstream = default_upstream
    @token = token
    @ids = ids

    @logger = logger
    @filepath = filepath
  end

  def call
    log "Importing providers from eInfraCentral..."

    begin
      rp = Importers::Request.new(@eic_base_url, "provider", unirest: @unirest, token: @token).call
    rescue Errno::ECONNREFUSED
      abort("import exited with errors - could not connect to #{@eic_base_url}")
    end

    @providers = rp.body["results"].index_by { |provider| provider["id"] }

    updated = 0
    created = 0
    not_modified = 0
    total_provider_count = @providers.length
    output = []

    @providers.select { |_p, bodu| @ids.empty? || @ids.include?(_p) }.each do |eid, provider_data|
      output.append(provider_data)
      image_url = provider_data["logo"]
      updated_provider_data = Importers::Provider.new(provider_data, Time.now.to_i, "rest").call

      mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
        "provider_sources.eid": eid) || Provider.find_by(name: updated_provider_data[:name])

      provider_source = ProviderSource.find_by(source_type: "eic", eid: eid)

      if mapped_provider.blank?
        created += 1
        log "Adding [NEW] provider: #{updated_provider_data[:name]}, eid: #{updated_provider_data[:pid]}"
        unless @dry_run
          mapped_provider = Provider.create!(updated_provider_data)
          Importers::Logo.new(mapped_provider, image_url).call
          provider_source = ProviderSource.create!(provider_id: mapped_provider.id, source_type: "eic", eid: eid)
        end
      elsif provider_source.present? && provider_source.id == mapped_provider.upstream_id
        updated += 1
        log "Updating [EXISTING] provider: #{updated_provider_data[:name]}, eid: #{updated_provider_data[:pid]}"
        if mapped_provider.upstream_id == provider_source.id
          unless @dry_run
            mapped_provider.update!(updated_provider_data)
            Importers::Logo.new(mapped_provider, image_url).call
            if mapped_provider.sources.blank?
              provider_source = ProviderSource.create!(provider_id: mapped_provider.id, source_type: "eic", eid: eid)
            end
          end
        end
      else
        not_modified += 1
        log "Provider upstream is not set to EIC, not updating #{mapped_provider.name}, id: #{mapped_provider.pid}"
      end
      if @default_upstream == :eic && provider_source.present?
        mapped_provider.update(upstream_id: provider_source.id)
      end
      rescue ActiveRecord::RecordInvalid => e
        log "[WARN] Provider #{updated_provider_data[:name]} #{updated_provider_data[:pid]} cannot be created. #{e}"
    end

    Provider.reindex

    log "PROCESSED: #{total_provider_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

    unless @filepath.nil?
      open(@filepath, "w") do |file|
        file << JSON.pretty_generate(output)
      end
    end
  end

  private
    def log(msg)
      @logger.call(msg)
    end
end
