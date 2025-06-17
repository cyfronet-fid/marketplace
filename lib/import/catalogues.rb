# frozen_string_literal: true

class Import::Catalogues
  include Importable

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
      parsed_catalogue_data = Importers::Catalogue.call(external_data["catalogue"], Time.now.to_i)
      parsed_catalogue_data["status"] = object_status(external_data["active"], external_data["suspended"])
      current_catalogue = Catalogue.find_by(pid: parsed_catalogue_data[:pid])

      next if @dry_run

      if current_catalogue.blank?
        log "[INFO] Adding [NEW] catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]}"
        catalogue = Catalogue.new(parsed_catalogue_data)
        set_logo(catalogue, external_data.dig("catalogue", "logo"))
        catalogue.save!
        log "[INFO] Catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]} added successfully"
      else
        log "[INFO] Updating [EXISTING] catalogue: #{parsed_catalogue_data[:name]}, eid: #{parsed_catalogue_data[:pid]}"
        current_catalogue.update!(parsed_catalogue_data)
        set_logo(current_catalogue, external_data.dig("catalogue", "logo"))
        current_catalogue.save!
        log "[INFO] Catalogue: #{parsed_catalogue_data[:name]}, " +
              "eid: #{parsed_catalogue_data[:pid]} updated successfully"
      end
    rescue ActiveRecord::RecordInvalid
      log "[WARN] Catalogue #{parsed_catalogue_data[:name]},
            eid: #{parsed_catalogue_data[:pid]} cannot be updated.
            Errors: #{catalogue.errors.full_messages.join(", ")}"
    rescue StandardError => e
      log "[WARN] Unexpected #{e}! Catalogue #{parsed_catalogue_data[:name]},
                eid: #{parsed_catalogue_data[:pid]} cannot be updated"
    end

    File.open(@filepath, "w") { |file| file << JSON.pretty_generate(@request_catalogues) } unless @filepath.nil?
  end

  private

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
    Array(rp.body["results"])
  end

  def set_logo(catalogue, logo)
    catalogue.set_default_logo
    Importers::Logo.new(catalogue, logo).call
  end
end
