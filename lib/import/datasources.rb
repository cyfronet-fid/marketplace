# frozen_string_literal: true

class Import::Datasources
  include Importable

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    ids: [],
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    default_upstream: :eosc_registry,
    token: nil
  )
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @default_upstream = default_upstream
    @token = token

    @logger = logger
    @ids = ids || []
    @filepath = filepath
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  def call
    log "Importing datasources from EOSC Registry..."

    begin
      @token ||= Importers::Token.new(faraday: @faraday).receive_token
      response =
        Importers::Request.new(@eosc_registry_base_url, "public/datasource", faraday: @faraday, token: @token).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      output = response
      File.open(@filepath, "w") { |file| file << output } unless @filepath.nil?
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end

    created = 0
    updated = 0
    not_modified = 0
    total_datasource_count = response.body["results"].length
    output = []

    log "EOSC Registry - all datasources #{total_datasource_count}"

    response.body["results"]
      .select { |res| @ids.empty? || @ids.include?(res["id"]) }
      .each do |ds_data|
        output.append(ds_data)

        raise "Unexpected type #{ds_data["type"]}" unless ds_data["type"] == "DataSource"

        synchronized_at = Time.now.to_i
        service_attrs = Importers::Service.call(ds_data, synchronized_at, @eosc_registry_base_url, @token)
        ds_delta = Importers::Datasource.call(ds_data)
        attrs = service_attrs.merge(ds_delta).merge(type: "Datasource", status: :published)
        image_url = attrs.delete(:logo_url)

        if (source = ServiceSource.find_by(eid: ds_data["id"], source_type: "eosc_registry")).nil?
          created += 1
          log "Adding [NEW] datasource: #{attrs[:name]}, eid: #{ds_data["id"]}"
          next if @dry_run

          ds = Datasource.new(attrs)
          if ds.valid?
            Importers::Logo.call(ds, image_url) unless @rescue_mode
            ds = Service::Create.call(ds)
            source = ServiceSource.create!(service_id: ds.id, eid: ds.pid, source_type: "eosc_registry")
            ds.update_column(:upstream_id, source.id) if @default_upstream == :eosc_registry
          else
            ds.status = :draft
            ds.save(validate: false)
            source = ServiceSource.create!(service_id: ds.id, eid: ds.pid, source_type: "eosc_registry")
            ds.update_column(:upstream_id, source.id) if @default_upstream == :eosc_registry
            log "Datasource #{ds.name}, eid: #{ds.pid} saved with errors: #{ds.errors.full_messages}"
          end
        else
          existing = Datasource.find_by(id: source.service_id)
          if existing&.upstream_id == source.id
            updated += 1
            log "Updating [EXISTING] datasource #{attrs[:name]}, id: #{source.id}, eid: #{ds_data["id"]}"
            next if @dry_run

            Importers::Logo.call(existing, image_url) unless @rescue_mode
            Service::Update.call(existing, attrs)
          else
            log "Datasource upstream is not set to EOSC Registry," \
                  " not updating #{existing&.name}, id: #{source.id}"
            not_modified += 1
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        log "[ERROR] - #{e}! #{ds_data["name"]} (eid: #{ds_data["id"]}) will NOT be created"
      rescue StandardError => e
        log "[ERROR] - Unexpected #{e}! #{ds_data["name"]} (eid: #{ds_data["id"]}) will NOT be created"
      end
    log "PROCESSED: #{total_datasource_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

    Datasource.reindex

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  private

  def log(msg)
    @logger.call(msg)
  end
end
