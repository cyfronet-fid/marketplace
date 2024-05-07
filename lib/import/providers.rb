# frozen_string_literal: true

require "image_processing/mini_magick"

class Import::Providers
  include Importable

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    ids: [],
    default_upstream: :eosc_registry,
    token: nil,
    rescue_mode: false
  )
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @default_upstream = default_upstream
    @token = token
    @rescue_mode = rescue_mode
    @ids = ids

    @logger = logger
    @filepath = filepath

    @updated_count = 0
    @created_count = 0
  end

  def call
    log "Importing providers from EOSC Registry #{@eosc_registry_base_url}..."
    @request_providers = external_providers_data.select { |pro| @ids.empty? || @ids.include?(pro["provider"]["id"]) }

    @request_providers.each do |external_data|
      external_provider_data = external_data["provider"]
      eid = external_provider_data["id"]
      parsed_provider_data = Importers::Provider.new(external_provider_data, Time.now.to_i, "rest").call
      parsed_provider_data["status"] = object_status(external_data["active"], external_data["suspended"])
      eosc_registry_provider =
        Provider.joins(:sources).find_by("provider_sources.source_type": "eosc_registry", "provider_sources.eid": eid)
      current_provider = eosc_registry_provider || Provider.find_by(pid: parsed_provider_data[:pid])

      provider_source = ProviderSource.find_by(source_type: "eosc_registry", eid: eid)

      next if @dry_run

      if current_provider.blank?
        create_provider(parsed_provider_data, external_provider_data["logo"], eid)
      elsif provider_source.present? && provider_source.id == current_provider.upstream_id
        update_provider(current_provider, parsed_provider_data, external_provider_data["logo"])
      end
      if @default_upstream == :eosc_registry && provider_source.present?
        current_provider.update(upstream_id: provider_source.id)
      end
    rescue ActiveRecord::RecordInvalid
      log "[WARN] Provider #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated. #{current_provider.errors.full_messages}"
    rescue StandardError => e
      log "[WARN] Unexpected #{e}! Provider #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated"
    ensure
      log_status(current_provider, parsed_provider_data, provider_source)
    end

    Provider.reindex

    not_modified = @request_providers.length - @created_count - @updated_count
    log "PROCESSED: #{@request_providers.length}, CREATED: #{@created_count}, " \
          "UPDATED: #{@updated_count}, NOT MODIFIED: #{not_modified}"

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(@request_providers) } unless @filepath.nil?
  end

  private

  def name(external_data)
    external_data.dig("provider", "name")
  end

  def eid(external_data)
    external_data.dig("provider", "id")
  end

  def log(msg)
    @logger.call(msg)
  end

  def log_status(current_provider, parsed_provider_data, provider_source)
    if current_provider.blank?
      @created_count += 1
      log "Adding [NEW] provider: #{parsed_provider_data[:name]}, eid: #{parsed_provider_data[:pid]}"
    elsif provider_source.present? && provider_source.id == current_provider.upstream_id
      @updated_count += 1
      log "Updating [EXISTING] provider: #{parsed_provider_data[:name]}, eid: #{parsed_provider_data[:pid]}"
    else
      log "Provider upstream is not set to EOSC Registry, " \
            "not updating #{current_provider.name}, id: #{current_provider.pid}"
    end
  end

  def create_provider(parsed_provider_data, image_url, eid)
    current_provider = Provider.new(parsed_provider_data)
    current_provider.set_default_logo
    current_provider.save(validate: false)
    provider_source = ProviderSource.create!(provider_id: current_provider.id, source_type: "eosc_registry", eid: eid)
    current_provider.upstream_id = provider_source.id
    if current_provider.invalid?
      provider_source.update!(errored: current_provider.errors.to_hash)
      log "Provider #{parsed_provider_data[:name]},
              eid: #{parsed_provider_data[:pid]} saved with errors: #{current_provider.errors.full_messages}"
    end

    Importers::Logo.new(current_provider, image_url).call unless @rescue_mode
    current_provider.save(validate: false)
  end

  def update_provider(current_provider, parsed_provider_data, image_url)
    current_provider.update(parsed_provider_data)
    if current_provider.valid?
      current_provider.save!

      Importers::Logo.new(current_provider, image_url).call unless @rescue_mode
      current_provider.save!
    else
      current_provider.sources.first.update!(errored: current_provider.errors.to_hash)
    end
  end

  def external_providers_data
    begin
      @token ||= Importers::Token.new(faraday: @faraday).receive_token
      rp =
        Importers::Request.new(@eosc_registry_base_url, "public/provider/bundle", faraday: @faraday, token: @token).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end
    rp.body["results"]
  end
end
