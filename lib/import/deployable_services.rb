# frozen_string_literal: true

class Import::DeployableServices
  include Importable

  def initialize(
    eosc_registry_base_url,
    dry_run: true,
    filepath: nil,
    faraday: Faraday,
    logger: ->(msg) { puts msg },
    ids: [],
    default_upstream: :eosc_registry,
    token: nil,
    rescue_mode: false
  )
    super()
    @eosc_registry_base_url = eosc_registry_base_url
    @dry_run = dry_run
    @faraday = faraday
    @default_upstream = default_upstream
    @token = token
    @rescue_mode = rescue_mode
    @ids = ids

    @logger = logger
    @filepath = filepath

    @updated_count = 0
    @created_count = 0
  end

  def call
    log "Importing deployable services from EOSC Registry #{@eosc_registry_base_url}... Rescue mode: #{@rescue_mode}"
    @request_deployable_services =
      external_deployable_services_data.select { |ds| @ids.empty? || @ids.include?(ds["id"]) }

    @request_deployable_services.each do |external_data|
      eid = external_data["id"]
      parsed_deployable_service_data =
        Importers::DeployableService.call(external_data, Time.now.to_i, @eosc_registry_base_url, @token)
      parsed_deployable_service_data["status"] = object_status(
        external_data["active"],
        external_data["suspended"]
      ) if external_data.key?("active")
      eosc_registry_deployable_service =
        DeployableService.joins(:sources).find_by(
          "deployable_service_sources.source_type": "eosc_registry",
          "deployable_service_sources.eid": eid
        )
      current_deployable_service =
        eosc_registry_deployable_service || DeployableService.find_by(pid: parsed_deployable_service_data[:pid])

      deployable_service_source = DeployableServiceSource.find_by(source_type: "eosc_registry", eid: eid)

      next if @dry_run

      if current_deployable_service.blank?
        create_deployable_service(parsed_deployable_service_data, external_data["logo"], eid)
      elsif deployable_service_source.present? && deployable_service_source.id == current_deployable_service.upstream_id
        update_deployable_service(current_deployable_service, parsed_deployable_service_data, external_data["logo"])
      end
      if @default_upstream == :eosc_registry && deployable_service_source.present?
        current_deployable_service.update(upstream_id: deployable_service_source.id)
      end
    rescue ActiveRecord::RecordInvalid
      log "[WARN] DeployableService #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated. #{current_deployable_service.errors.full_messages}"
    rescue StandardError => e
      log "[WARN] Unexpected #{e}! DeployableService #{name(external_data)},
                eid: #{eid(external_data)} cannot be updated"
    ensure
      log_status(current_deployable_service, parsed_deployable_service_data, deployable_service_source)
    end

    not_modified = @request_deployable_services.length - @created_count - @updated_count
    log "PROCESSED: #{@request_deployable_services.length}, CREATED: #{@created_count}, " \
          "UPDATED: #{@updated_count}, NOT MODIFIED: #{not_modified}"

    unless @filepath.nil?
      File.open(@filepath, "w") { |file| file << JSON.pretty_generate(@request_deployable_services) }
    end
  end

  private

  def name(external_data)
    external_data["name"]
  end

  def eid(external_data)
    external_data["id"]
  end

  def log(msg)
    @logger.call(msg)
  end

  def log_status(current_deployable_service, parsed_deployable_service_data, deployable_service_source)
    if current_deployable_service.blank?
      @created_count += 1
      log "Adding [NEW] deployable service: #{parsed_deployable_service_data[:name]}" +
            ", eid: #{parsed_deployable_service_data[:pid]}"
    elsif deployable_service_source.present? && deployable_service_source.id == current_deployable_service.upstream_id
      @updated_count += 1
      log "Updating [EXISTING] deployable service: #{parsed_deployable_service_data[:name]}" +
            ", eid: #{parsed_deployable_service_data[:pid]}"
    else
      log "[SKIPPING] #{parsed_deployable_service_data[:name]}," +
            " eid: #{parsed_deployable_service_data[:pid]} - not managed by EOSC Registry"
    end
  end

  def external_deployable_services_data
    begin
      @token ||= Importers::Token.new(faraday: @faraday).receive_token
      rp =
        Importers::Request.new(
          @eosc_registry_base_url,
          "public/deployableService",
          faraday: @faraday,
          token: @token
        ).call
    rescue Errno::ECONNREFUSED, Importers::Token::RequestError => e
      abort("import exited with errors - could not connect to #{@eosc_registry_base_url} \n #{e.message}")
    end
    Array(rp.body["results"])
  end

  def create_deployable_service(parsed_deployable_service_data, logo_url, eid)
    deployable_service = DeployableService.new(parsed_deployable_service_data)
    deployable_service.save(validate: false)
    source =
      DeployableServiceSource.create!(
        deployable_service_id: deployable_service.id,
        source_type: "eosc_registry",
        eid: eid
      )
    deployable_service.upstream_id = source.id
    if deployable_service.invalid?
      source.update!(errored: deployable_service.errors.to_hash)
      log "DeployableService #{parsed_deployable_service_data[:name]},
              eid: #{parsed_deployable_service_data[:pid]}
              saved with errors: #{deployable_service.errors.full_messages}"
    end

    set_logo(deployable_service, logo_url)
    deployable_service.save(validate: false)
  end

  def update_deployable_service(deployable_service, parsed_deployable_service_data, logo_url)
    deployable_service.update(parsed_deployable_service_data)
    if deployable_service.valid?
      deployable_service.save!

      set_logo(deployable_service, logo_url)
      deployable_service.save!
    else
      deployable_service.sources.first.update!(errored: deployable_service.errors.to_hash)
    end
  end

  def set_logo(deployable_service, logo)
    deployable_service.set_default_logo
    Importers::Logo.new(deployable_service, logo).call
  end
end
