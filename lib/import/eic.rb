# frozen_string_literal: true

module Import
  class Eic
    def initialize(eic_base_url,
                   dry_run: true,
                   ids: [],
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
      @ids = ids || []
      @filepath = filepath
    end

    def call
      log "Importing services from eInfraCentral..."

      begin
        r = Importers::Request.new(@eic_base_url, "resource/rich", unirest: @unirest, token: @token).call
      rescue Errno::ECONNREFUSED
        abort("import exited with errors - could not connect to #{@eic_base_url}")
      end

      updated = 0
      created = 0
      not_modified = 0
      total_service_count = r.body["results"].length
      output = []

      log "EIC - all services #{total_service_count}"

      r.body["results"].select { |_r| @ids.empty? || @ids.include?(_r["service"]["id"]) }
          .each do |service_data|
        service = service_data["service"]
        output.append(service_data)

        synchronized_at = service_data["metadata"]["modifiedAt"].to_i
        service = Importers::Service.new(service, synchronized_at, @eic_base_url, @token, "rest").call
        image_url = service["logo"]

        begin
          if (service_source = ServiceSource.find_by(eid: service[:pid], source_type: "eic")).nil?
            created += 1
            log "Adding [NEW] service: #{service[:name]}, eid: #{service[:pid]}"
            unless @dry_run
              service = Service.new(service)
              Importers::Logo.new(service, image_url).call
              if service.valid?
                service = Service::Create.new(service).call
                service_source = ServiceSource.create!(service_id: service.id, eid: service.pid, source_type: "eic")
                if @default_upstream == :eic
                  service.update(upstream_id: service_source.id)
                end
              else
                service.status = "errored"
                service.save(validate: false)
                service_source = ServiceSource.create!(service_id: service.id, eid: service.pid, source_type: "eic")
                if @default_upstream == :eic
                  service.upstream_id = service_source.id
                  service.save(validate: false)
                end
                log "Service #{service.name}, eid: #{service.pid} saved with errors: #{service.errors.messages}"
              end
            end
          else
            existing_service = Service.find_by(id: service_source.service_id)
            if existing_service.upstream_id == service_source.id
              updated += 1
              log "Updating [EXISTING] service #{service[:name]}, id: #{service_source.id}, eid: #{service[:pid]}"
              unless @dry_run
                Service::Update.new(existing_service, service).call
              end
            else
              not_modified += 1
              log "Service upstream is not set to EIC, not updating #{existing_service.name}, id: #{service_source.id}"
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          log "ERROR - #{invalid}! #{service[:name]} (eid: #{service[:pid]}) will NOT be created (please contact catalog manager)"
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
      def log(msg)
        @logger.call(msg)
      end
  end
end
