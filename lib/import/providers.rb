# frozen_string_literal: true

require "mini_magick"

class Import::Providers
  def initialize(eic_base_url,
                 dry_run: true,
                 filepath: nil,
                 unirest: Unirest,
                 logger: ->(msg) { puts msg },
                 default_upstream: :mp,
                 token: nil)
    @eic_base_url = eic_base_url
    @dry_run = dry_run
    @unirest = unirest
    @default_upstream = default_upstream
    @token = token

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

    output = []

    begin
      @providers.each do |eid, provider_data|
        output.append(provider_data)
        image_url = provider_data["logo"]
        updated_provider_data = Importers::Provider.new(provider_data, Time.now.to_i, "rest").call

        mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
          "provider_sources.eid": eid) || Provider.find_by(name: updated_provider_data[:name])
        if mapped_provider.blank?
          log "Adding [NEW] provider: #{updated_provider_data[:name]}, eid: #{updated_provider_data[:pid]}"
          mapped_provider = Provider.create!(updated_provider_data)
          Importers::Logo.new(mapped_provider, image_url).call
          ProviderSource.create!(provider_id: mapped_provider.id, source_type: "eic", eid: eid)
        else
          log "Updating [EXISTING] provider: #{updated_provider_data[:name]}, eid: #{updated_provider_data[:pid]}"
          mapped_provider.update!(updated_provider_data)
          Importers::Logo.new(mapped_provider, image_url).call
        end
      end
    end

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
