# frozen_string_literal: true

module Import
  class Guidelines
    def initialize(
      eosc_registry_base_url,
      dry_run: true,
      filepath: nil,
      faraday: Faraday,
      logger: ->(msg) { puts msg },
      token: nil
    )
      @eosc_registry_base_url = eosc_registry_base_url
      @dry_run = dry_run
      @faraday = faraday
      @token = token

      @logger = logger
      @filepath = filepath

      @updated_count = 0
      @created_count = 0
    end

    def call
      import_guidelines
      connect_guidelines
    end

    def import_guidelines
      log "Importing guidelines from EOSC Registry #{@eosc_registry_base_url}..."
      @request_guidelines = external_guidelines_data("public/interoperabilityRecord")

      @request_guidelines.each do |external_data|
        eid = external_data["id"]
        title = external_data["title"]
        parsed_guideline_data = { title: title, eid: eid }
        existing_guideline = Guideline.find_by(eid: eid)

        next if @dry_run

        if existing_guideline.blank?
          create_guideline(parsed_guideline_data)
        else
          update_guideline(existing_guideline, parsed_guideline_data)
        end
      rescue ActiveRecord::RecordInvalid
        log "[WARN] Guideline #{external_data["title"]},
                eid: #{external_data["id"]} cannot be updated. #{existing_guideline.errors.full_messages}"
      rescue StandardError => e
        log "[WARN] Unexpected #{e}! Provider #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated"
      ensure
        log_status(existing_guideline, parsed_guideline_data)
      end

      not_modified = @request_guidelines.length - @created_count - @updated_count
      log "PROCESSED: #{@request_guidelines.length}, CREATED: #{@created_count}, " \
            "UPDATED: #{@updated_count}, NOT MODIFIED: #{not_modified}"

      unless @filepath.nil?
        File.open(@filepath, "w") do |file|
          file << JSON.pretty_generate(@request_guidelines.map { |_, request_data| request_data })
        end
      end
    end

    def connect_guidelines
      log "Importing guidelines connections from EOSC Registry #{@eosc_registry_base_url}..."
      @request_connections = external_guidelines_data("public/resourceInteroperabilityRecord")

      @request_connections.each do |external_data|
        eid = external_data["resourceId"]
        guideline_eids = external_data["interoperabilityRecordIds"]
        if (service_source = ServiceSource.find_by(eid: eid, source_type: "eosc_registry")).nil?
          log "Service source #{eid} not found"
          next
        end

        log "Connecting guidelines to #{eid}"

        next if @dry_run

        if (service = Service.find_by(id: service_source.service_id)).nil?
          log "Service #{eid} not found but its source exists with id: #{service_source.id}"
          next
        end
        guidelines = Guideline.where(eid: [guideline_eids])
        service.guidelines = guidelines
        service.save!
      end
    end

    def create_guideline(parsed_guideline)
      current_guideline = Guideline.new(parsed_guideline)
      current_guideline.save!
    end

    def update_guideline(current_guideline, parsed_guideline)
      current_guideline.update(parsed_guideline)
      current_guideline.save!
    end

    def external_guidelines_data(record_type)
      begin
        # currently aai tokens seems to be broken
        # @token = Importers::Token.new(faraday: @faraday).receive_token
        rp = Importers::Request.new(@eosc_registry_base_url, record_type, faraday: @faraday, token: @token).call
      rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
        abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
      end
      rp.body["results"]
    end

    def log_status(current_guideline, parsed_guideline_data)
      if current_guideline.blank?
        @created_count += 1
        log "Adding [NEW] guideline: #{parsed_guideline_data[:title]}, eid: #{parsed_guideline_data[:eid]}"
      else
        @updated_count += 1
        log "Updating [EXISTING] guideline: #{parsed_guideline_data[:title]}, eid: #{parsed_guideline_data[:eid]}"
      end
    end

    def log(msg)
      @logger.call(msg)
    end
  end
end
