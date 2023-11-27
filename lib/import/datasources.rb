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
        Importers::Request.new(
          @eosc_registry_base_url,
          "/public/datasource/adminPage",
          faraday: @faraday,
          token: @token
        ).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      output = response
      File.open(@filepath, "w") { |file| file << output } unless @filepath.nil?
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end

    updated = 0
    not_modified = 0
    total_datasource_count = response.body["results"].length
    output = []

    log "EOSC Registry - all datasources #{total_datasource_count}"

    response.body["results"]
      .select { |res| @ids.empty? || @ids.include?(res["id"]) }
      .each do |datasource_data|
        datasource = datasource_data&.[]("datasource")
        ppid =
          datasource_data&.dig("identifiers", "alternativeIdentifiers")&.find { |id| id["type"] == "PID" }&.[]("value")
        output.append(datasource_data)

        datasource = Importers::Datasource.call(datasource, "rest")
        datasource["type"] = "Datasource"
        if (datasource_source = ServiceSource.find_by(eid: eid(datasource_data), source_type: "eosc_registry")).nil?
          log "[WARN] Service id #{eid(datasource_data)} (PID: #{ppid}) doesn't exist."
        else
          existing_datasource = Service.find_by(pid: eid(datasource_data))
          if existing_datasource.upstream_id == datasource_source.id
            updated += 1
            log "Updating [EXISTING] datasource #{existing_datasource.name}, " +
                  "id: #{datasource_source["id"]}, eid: #{eid(datasource_data)}"
            Service::Update.new(existing_datasource, datasource).call unless @dry_run
          else
            log "Datasource upstream is not set to EOSC Registry," \
                  " not updating #{existing_datasource.name}, id: #{datasource_source.id}"
            not_modified += 1
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        log "[ERROR] - #{e}! #{name(datasource_data)} (eid: #{eid(datasource_data)}) " \
              "will NOT be created (please contact catalog manager)"
      rescue StandardError => e
        log "[ERROR] - Unexpected #{e}! #{name(datasource_data)} (eid: #{eid(datasource_data)}) will NOT be created!"
      end
    log "PROCESSED: #{total_datasource_count}, " + "UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

    Datasource.reindex

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

  private

  def name(datasource_data)
    datasource_data.dig("datasource", "name")
  end

  def eid(datasource_data)
    datasource_data.dig("datasource", "serviceId")
  end

  def update_from_eosc_registry(datasource, datasource_source, validate)
    if @default_upstream == "eosc_registry"
      datasource.upstream_id = datasource_source.id
      datasource.save(validate: validate)
    end
  end

  def log(msg)
    @logger.call(msg)
  end
end
