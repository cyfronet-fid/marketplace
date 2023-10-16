# frozen_string_literal: true

class Import::Catalogues
  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    ids: [],
    token: nil
  )
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @token = token
    @ids = ids

    @logger = logger
    @filepath = filepath

    @updated_count = 0
    @created_count = 0
  end

  def call
    log "Importing catalogues from EOSC Registry..."

    @request_catalogues = external_catalogues_data.select { |pro| @ids.empty? || @ids.include?(pro["id"]) }

    total_catalogue_count = @request_catalogues.length

    log "EOSC Registry - all catalogues #{total_catalogue_count}"

    @request_catalogues.each do |external_data|
      external_catalogue_data = external_data["catalogue"]
      parsed_catalogue_data = Importers::Catalogue.new(external_catalogue_data, Time.now.to_i, "rest").call
      current_catalogue = Catalogue.find_by(pid: parsed_catalogue_data[:pid])

      next if @dry_run

      if current_catalogue.blank?
        log "[INFO] Adding [NEW] catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]}"
        catalogue = Catalogue.new(parsed_catalogue_data)
        catalogue.save!
        log "[INFO] Catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]} added successfully"
      else
        log "[INFO] Updating [EXISTING] catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]}"
        current_catalogue.update(parsed_catalogue_data)
        current_catalogue.save!
        log "[INFO] Catalogue: #{parsed_catalogue_data[:name]}, " +
              "eid: #{parsed_catalogue_data[:pid]} updated successfully"
      end
    rescue ActiveRecord::RecordInvalid
      log "[WARN] Catalogue #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated."
    rescue StandardError => e
      log "[WARN] Unexpected #{e}! Catalogue #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated"
    end

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(@request_catalogues) } unless @filepath.nil?
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

  def external_catalogues_data
    begin
      @token ||= Importers::Token.new(faraday: @faraday).receive_token
      rp = Importers::Request.new(@eosc_registry_base_url, "catalogue/bundle", faraday: @faraday, token: @token).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end
    rp.body["results"]
  end
end
