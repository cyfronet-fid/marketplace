# frozen_string_literal: true

module Import
  class Resources
    def initialize(eosc_registry_base_url,
                   dry_run: true,
                   ids: [],
                   filepath: nil,
                   faraday: Faraday,
                   logger: ->(msg) { puts msg },
                   default_upstream: :mp,
                   token: nil)
      @eosc_registry_base_url = eosc_registry_base_url
      @dry_run = dry_run
      @faraday = faraday
      @default_upstream = default_upstream
      @token = token

      @logger = logger
      @ids = ids || []
      @filepath = filepath
    end

    def call
      log "Importing resources from EOSC Registry..."

      begin
        r = Importers::Request.new(@eosc_registry_base_url, "resource/rich", faraday: @faraday, token: @token).call
      rescue Errno::ECONNREFUSED
        abort("import exited with errors - could not connect to #{@eosc_registry_base_url}")
      end

      updated = 0
      created = 0
      not_modified = 0
      total_service_count = r.body["results"].length
      output = []

      log "EOSC Registry - all services #{total_service_count}"

      r.body["results"].select { |_r| @ids.empty? || @ids.include?(_r["service"]["id"]) }
          .each do |service_data|
        service = service_data["service"]
        output.append(service_data)

        synchronized_at = service_data["metadata"]["modifiedAt"].to_i
        image_url = service["logo"]
        service = Importers::Service.new(service, synchronized_at, @eosc_registry_base_url, @token, "rest").call

        begin
          if (service_source = ServiceSource.find_by(eid: service[:pid], source_type: "eosc_registry")).nil?
            created += 1
            log "Adding [NEW] service: #{service[:name]}, eid: #{service[:pid]}"
            unless @dry_run
              service = Service.new(service)
              if service.valid?
                service = Service::Create.new(service).call
                service_source = ServiceSource.create!(service_id: service.id,
                                                       eid: service.pid,
                                                       source_type: "eosc_registry")
                update_from_eosc_registry(service, service_source, true)

                Importers::Logo.new(service, image_url).call
                service.save!
              else
                service.status = "errored"
                service.save(validate: false)
                service_source = ServiceSource.create!(service_id: service.id,
                                                       eid: service.pid,
                                                       source_type: "eosc_registry")
                update_from_eosc_registry(service, service_source, false)
                log "Service #{service.name}, eid: #{service.pid} saved with errors: #{service.errors.full_messages}"

                Importers::Logo.new(service, image_url).call
                service.save(validate: false)
              end
            end
          else
            existing_service = Service.find_by(id: service_source.service_id)
            if existing_service.upstream_id == service_source.id
              updated += 1
              log "Updating [EXISTING] service #{service[:name]}, id: #{service_source.id}, eid: #{service[:pid]}"
              unless @dry_run
                Service::Update.new(existing_service, service).call

                Importers::Logo.new(existing_service, image_url).call
                existing_service.save!
              end
            else
              not_modified += 1
              log "Service upstream is not set to EOSC Registry," +
                    " not updating #{existing_service.name}, id: #{service_source.id}"
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          log "ERROR - #{invalid}! #{service[:name]} (eid: #{service[:pid]}) " +
                "will NOT be created (please contact catalog manager)"
        rescue StandardError => error
          log "ERROR - Unexpected #{error}! #{service[:name]} (eid: #{service[:pid]}) will NOT be created!"
        end
      end
      log "PROCESSED: #{total_service_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

      Service.reindex

      unless @filepath.nil?
        open(@filepath, "w") do |file|
          file << JSON.pretty_generate(output)
        end
      end
    end

    private
      def update_from_eosc_registry(service, service_source, validate)
        if @default_upstream == :eosc_registry
          service.upstream_id = service_source.id
          service.save(validate: validate)
        end
      end

      def log(msg)
        @logger.call(msg)
      end
  end
end
