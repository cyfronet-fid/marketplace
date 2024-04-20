# frozen_string_literal: true

class Import::Resources
  include Importable

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    ids: [],
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
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
    @logger = logger
    @ids = ids || []
    @filepath = filepath
  end

  def call
    log "Importing resources from EOSC Registry (#{@eosc_registry_base_url})..."

    begin
      @token ||= Importers::Token.new(faraday: @faraday).receive_token
      response =
        Importers::Request.new(
          @eosc_registry_base_url,
          "public/service/adminPage",
          faraday: @faraday,
          token: @token
        ).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end

    updated = 0
    created = 0
    not_modified = 0
    total_service_count = response.body["results"].length
    output = []

    log "EOSC Registry - all services #{total_service_count}"

    response.body["results"]
      .select { |res| @ids.empty? || @ids.include?(res["service"]["id"]) }
      .each do |service_data|
        service = service_data["service"].merge(service_data["resourceExtras"] || {})
        output.append(service_data)

        synchronized_at = service_data["metadata"]["modifiedAt"].to_i
        image_url = service["logo"]
        service = Importers::Service.new(service, synchronized_at, @eosc_registry_base_url, @token, "rest").call
        service[:status] = object_status(service_data["service"]["active"], service_data["service"]["suspended"])
        if (service_source = ServiceSource.find_by(eid: service[:pid], source_type: "eosc_registry")).nil?
          created += 1
          log "Adding [NEW] service: #{service[:name]}, eid: #{service[:pid]}"
          unless @dry_run
            service = Service.new(service)
            if service.valid?
              Importers::Logo.new(service, image_url).call unless @rescue_mode
              service = Service::Create.call(service)
              service_source =
                ServiceSource.create!(service_id: service.id, eid: service.pid, source_type: "eosc_registry")
              update_from_eosc_registry(service, service_source, true)
            else
              service.status = service_data["active"] ? :errored : :draft
              service_source =
                ServiceSource.create!(service_id: service.id, eid: service.pid, source_type: "eosc_registry")
              update_from_eosc_registry(service, service_source, false)
              log "Service #{service.name}, eid: #{service.pid} saved with errors: #{service.errors.full_messages}"

              Importers::Logo.call(service, image_url) unless @rescue_mode
              service.save(validate: false)
            end
          end
        else
          existing_service = Service.find_by(id: service_source.service_id)
          if existing_service.upstream_id == service_source.id
            updated += 1
            log "Updating [EXISTING] service #{service[:name]}, id: #{service_source.id}, eid: #{service[:pid]}"
            unless @dry_run
              Importers::Logo.call(existing_service, image_url) unless @rescue_mode
              Service::Update.call(existing_service, service)
            end
          else
            existing_service = Service.find_by(id: service_source.service_id)
            if existing_service.upstream_id == service_source.id
              updated += 1
              log "Updating [EXISTING] service #{service[:name]}, id: #{service_source.id}, eid: #{service[:pid]}"
              unless @dry_run
                Importers::Logo.call(existing_service, image_url) unless @rescue_mode
                Service::Update.call(existing_service, service)
              end
            else
              not_modified += 1
              log "Service upstream is not set to EOSC Registry," \
                    " not updating #{existing_service.name}, id: #{service_source.id}"
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        log "ERROR - #{e}! #{name(service_data)} (eid: #{eid(service_data)}) " \
              "will NOT be created (please contact catalog manager)"
      rescue StandardError => e
        log "ERROR - Unexpected #{e}! #{name(service_data)} (eid: #{eid(service_data)}) will NOT be created!"
      end
    log "PROCESSED: #{total_service_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

    Service.reindex

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(output) } unless @filepath.nil?
  end

  private

  def name(service_data)
    service_data.dig("service", "name")
  end

  def eid(service_data)
    service_data.dig("service", "id")
  end

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
