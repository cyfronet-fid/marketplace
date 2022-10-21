# frozen_string_literal: true

module Import
  class Datasources
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
      created = 0
      not_modified = 0
      total_datasource_count = response.body["results"].length
      output = []

      log "EOSC Registry - all datasources #{total_datasource_count}"

      response.body["results"]
        .select { |res| @ids.empty? || @ids.include?(res["id"]) }
        .each do |datasource_data|
          datasource = datasource_data&.[]("datasource")&.merge(datasource_data["resourceExtras"] || {})
          datasource["status"] = datasource_data["active"] ? :published : :draft
          output.append(datasource_data)

          image_url = datasource["logo"]
          datasource = Importers::Datasource.call(datasource, Time.now, @eosc_registry_base_url, @token, "rest")
          if (
               datasource_source = DatasourceSource.find_by(eid: eid(datasource_data), source_type: "eosc_registry")
             ).nil?
            log "Adding [NEW] datasource: #{datasource[:name]}, eid: #{datasource[:pid]}"
            unless @dry_run
              datasource = Datasource.new(datasource)
              if datasource.valid?
                datasource.save
                datasource_source =
                  DatasourceSource.create!(
                    datasource_id: datasource.id,
                    eid: eid(datasource_data),
                    source_type: "eosc_registry"
                  )
                update_from_eosc_registry(datasource, datasource_source, true)

                Importers::Logo.new(datasource, image_url).call
                datasource.save!
              else
                datasource.save(validate: false)
                datasource_source =
                  DatasourceSource.create!(
                    datasource_id: datasource.id,
                    eid: "eosc.#{eid(datasource_data)}",
                    source_type: "eosc_registry"
                  )
                update_from_eosc_registry(datasource, datasource_source, false)
                log "Datasource #{datasource.name}, eid: #{datasource.pid} " +
                      "saved with errors: #{datasource.errors.full_messages}"

                Importers::Logo.new(datasource, image_url).call
                datasource.save(validate: false)
              end
            end
            created += 1
          else
            existing_datasource = Datasource.find_by(id: datasource_source.datasource_id)
            if existing_datasource.upstream_id == datasource_source.id
              updated += 1
              log "Updating [EXISTING] datasource #{datasource[:name]}, " +
                    "id: #{datasource_source["id"]}, eid: #{datasource[:pid]}"
              unless @dry_run
                Datasource::Update.new(existing_datasource, datasource).call

                Importers::Logo.new(existing_datasource, image_url).call
                existing_datasource.save!
              end
            else
              log "Datasource upstream is not set to EOSC Registry," \
                    " not updating #{existing_datasource.name}, id: #{datasource_source.id}"
              not_modified += 1
            end
          end
        rescue ActiveRecord::RecordInvalid => e
          log "ERROR - #{e}! #{name(datasource_data)} (eid: #{eid(datasource_data)}) " \
                "will NOT be created (please contact catalog manager)"
        rescue StandardError => e
          log "ERROR - Unexpected #{e}! #{name(datasource_data)} (eid: #{eid(datasource_data)}) will NOT be created!"
        end
      log "PROCESSED: #{total_datasource_count}, CREATED: #{created}, " +
            "UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

      Datasource.reindex

      File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
    end

    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def name(datasource_data)
      datasource_data["name"]
    end

    def eid(datasource_data)
      datasource_data["id"]
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
end
