# frozen_string_literal: true

require "mini_magick"

module Import
  class Eic
    def initialize(eic_base_url,
                   dry_run: true,
                   dont_create_providers: true,
                   ids: [],
                   filepath: nil,
                   unirest: Unirest,
                   logger: ->(msg) { puts msg },
                   default_upstream: :mp)
      @eic_base_url = eic_base_url
      @dry_run = dry_run
      @unirest = unirest
      @dont_create_providers = dont_create_providers
      @default_upstream = default_upstream

      @logger = logger
      @ids = ids || []
      @filepath = filepath
    end

    def call
      log "Importing services from eInfraCentral..."

      get_db_dependencies

      begin
        r = @unirest.get("#{@eic_base_url}/api/service/rich/all?quantity=10000&from=0",
                        headers: { "Accept" => "application/json" })
      rescue Errno::ECONNREFUSED
        abort("import:eic exited with errors - could not connect to #{@eic_base_url}")
      end

      if r.code != 200
        abort("import:eic exited with errors - could not fetch data (code: #{r.code})")
      end

      begin
        rp = @unirest.get("#{@eic_base_url}/api/provider/all?quantity=10000&from=0",
                         headers: { "Accept" => "application/json" })
      rescue Errno::ECONNREFUSED
        abort("import:eic exited with errors - could not connect to #{@eic_base_url}")
      end

      if rp.code != 200
        abort("import:eic exited with errors - could not fetch data (code: #{rp.code})")
      end

      @providers = rp.body["results"].index_by { |provider| provider["id"] }
      updated = 0
      created = 0
      not_modified = 0
      total_service_count = r.body["results"].length
      output = []

      log "EIC - all services #{total_service_count}"

      r.body["results"].select { |_r| @ids.empty? || @ids.include?(_r["id"]) }
          .each do |service|
        eid = service["id"]

        output.append(service)

        # TODO this should be moved to Offer.webpage
        url = service["url"]
        # order_url = service["order"]
        user_manual_url = service["userManual"]
        training_information_url = service["trainingInformation"]
        status_monitoring_url = service["statusMonitoring"]
        maintenance_url = service["maintenance"]
        order_url = service["order"]
        payment_model_url = service["paymentModel"]
        pricing_url = service["pricing"]
        helpdesk_url = service["helpdesk"]
        # feedback_url = service["feedback"]
        price_url = service["price"]
        service_level_agreement_url = service["serviceLevelAgreement"]
        terms_of_use = service["termsOfUse"] # list

        name = service["name"]
        tagline = service["tagline"]
        description = ReverseMarkdown.convert(service["description"], unknown_tags: :bypass, github_flavored: false)
        options = service["options"]
        user_value = service["userValue"]
        user_base = service["userBase"]
        image_url = service["symbol"]
        # last_update = service["lastUpdate"]
        # change_log = service["changeLog"]
        # category = service["category"]
        # subcategory = service["subcategory"]
        # tags = service["tags"]
        language_availability = Array(service["languages"] || "EN")
        geographical_availabilities = service["geographicalAvailabilities"]
        category = service["category"]
        funding_bodies = service["fundingBody"]
        funding_programs = service["fundingPrograms"]
        # category_name = service["categoryName"]
        # subcategory_name = service["subCategoryName"]
        trl = service["trl"]
        life_cycle_status = service["lifeCycleStatus"]
        resource_organisation_eid = service["resource_organisation"]
        provider_eids = service["providers"] || []
        version = service["version"]
        target_users = service["targetUsers"]

        logo = nil

        begin
          logo = open(image_url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          logo_content_type = logo.content_type

          if logo_content_type == "image/svg+xml"
            img = MiniMagick::Image.read(logo, ".svg")
            img.format "png" do |convert|
              convert.args.unshift "800x800"
              convert.args.unshift "-resize"
              convert.args.unshift "1200"
              convert.args.unshift "-density"
              convert.args.unshift "none"
              convert.args.unshift "-background"
            end

            logo = StringIO.new
            logo.write(img.to_blob)
            logo.seek(0)
            logo_content_type = "image/png"
          end
        rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, SocketError => e
          log "ERROR - there was a problem processing image for #{eid} #{image_url}: #{e}"
        rescue => e
          log "ERROR - there was a unexpected problem processing image for #{eid} #{image_url}: #{e}"
        end
        aggregated_description = [description, options, user_value, user_base].join("\n")


        mapped_resource_organisation =  map_providers([resource_organisation_eid], @providers, name, eid)
        mapped_providers = map_providers(provider_eids, @providers, name, eid)

        updated_service_data = {
            name: name,
            description: aggregated_description,
            tagline: tagline.blank? ? "NO IMPORTED TAGLINE" : tagline,
            # provider_id: ?
            # contact_emails: ?
            language_availability: language_availability || ["EN"],
            geographical_availabilities: geographical_availabilities || [],
            dedicated_for: [],
            terms_of_use_url: terms_of_use[0] || "",
            access_policies_url: price_url,
            sla_url: service_level_agreement_url || "",
            webpage_url: url || "",
            manual_url: user_manual_url || "",
            helpdesk_url: helpdesk_url || "",
            training_information_url: training_information_url || "",
            status_monitoring_url: status_monitoring_url || "",
            maintenance_url: maintenance_url || "",
            order_url: order_url || "",
            payment_model_url: payment_model_url || "",
            pricing_url: pricing_url || "",
            trl: Trl.where(eid: trl),
            life_cycle_status: LifeCycleStatus.where(eid: life_cycle_status),
            order_type: "open_access",
            status: "draft",
            funding_bodies: map_funding_bodies(funding_bodies),
            funding_programs: map_funding_programs(funding_programs),
            resource_organisation: mapped_resource_organisation[0],
            providers: mapped_providers,
            categories: map_category(category),
            scientific_domains: [@scientific_domain_other],
            version: version || "",
            target_users: map_target_users(target_users)
        }

        begin
          if (service_source = ServiceSource.find_by(eid: eid, source_type: "eic")).nil?
            created += 1
            log "Adding [NEW] service: #{name}, eid: #{eid}"
            unless @dry_run
              service = Service.new(updated_service_data)
              unless logo.nil?
                service.logo.attach(io: logo, filename: eid, content_type: logo_content_type)
              end
              service.save!
              service_source = ServiceSource.create!(service_id: service.id, eid: eid, source_type: "eic")
              if @default_upstream == :eic
                service.update(upstream_id: service_source.id)
              end
              create_default_offer!(service, name, eid, url)
            end
          else
            service = Service.find_by(id: service_source.service_id)
            if service.upstream_id == service_source.id
              updated += 1
              log "Updating [EXISTING] service #{service.name}, id: #{service_source.id}, eid: #{eid}"
              unless @dry_run
                service.update!(updated_service_data.except(:scientific_domains, :categories, :status))
                create_default_offer!(service, name, eid, url)
              end
            else
              not_modified += 1
              log "Service's upstream is not set to EIC, not updating #{service.name}, id: #{service_source.id}"
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          log "ERROR - #{invalid}! #{service.name} (eid: #{eid}) will NOT be created (please contact catalog manager)"
        rescue StandardError => error
          log "ERROR - Unexpected #{error}! #{service.name} (eid: #{eid}) will NOT be created!"
        end
      end
      log "PROCESSED: #{total_service_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"

      unless @filepath.nil?
        open(@filepath, "w") do |file|
          file << JSON.pretty_generate(output)
        end
      end
    end

    def map_target_users(target_users)
      TargetUser.where(eid: target_users)
    end

    def map_providers(providers_eids, providers, name, eid)
      mapped_providers = providers_eids&.map { |provider_eid|
        mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                           "provider_sources.eid": provider_eid)
        if mapped_provider.nil?
          if  @dont_create_providers
            log "[WARNING] No mapping for eic provider/resource_organisation '#{provider_eid}',
                                                            skipping service #{name}, #{eid}"
            return []
          else
            log "No mapped provider '#{provider_eid}', creating..."
            unless @dry_run
              if (mapped_provider = Provider.find_by(name: providers[provider_eid]["name"])).nil?
                mapped_provider = Provider.create!(name: providers[provider_eid]["name"])
              else
                log "Provider with name '#{providers[provider_eid]["name"]}' already exists, using existing provider"
              end
              ProviderSource.new(provider_id: mapped_provider.id, source_type: "eic", eid: provider_eid).save!
              mapped_provider
            end
          end
        else
          mapped_provider
        end
      }
      Array(mapped_providers)
    end

    def create_default_offer!(service, name, eid, url)
      if service&.offers.blank? && !url.blank?
        log "Adding [NEW] default offer for service: #{name}, eid: #{eid}"
        Offer.create!(name: "Offer", description: "#{name} Offer", order_type: "open_access",
                      webpage: url, status: service.status, service: service)
      elsif url.blank?
        log "[WARNING] Offer cannot be created, because url is empty"
      end
    rescue ActiveRecord::RecordInvalid => reason
      log "ERROR - Default offer for #{service.name} (eid: #{eid}) cannot be created. #{reason}"
    rescue StandardError => error
      log "ERROR - Default offer for #{service.name} (eid: #{eid}) cannot be created. Unexpected #{error}!"
    end

    def map_category(category)
      if @best_effort_category_mapping[category]
        [@best_effort_category_mapping[category]]
      else
        []
      end
    end

    def get_db_dependencies
      @scientific_domain_other = ScientificDomain.find_by!(name: "Other")

      @best_effort_category_mapping = {
          "storage":  Category.find_by!(name: "Storage"),
          "training": Category.find_by!(name: "Training & Support"),
          "security": Category.find_by!(name: "Security & Operations"),
          "analytics": Category.find_by!(name: "Processing & Analysis"),
          "data": Category.find_by!(name: "Data management"),
          "compute": Category.find_by!(name: "Compute"),
          "networking": Category.find_by!(name: "Networking"),
      }.stringify_keys
    end

    def map_funding_bodies(funding_bodies)
      FundingBody.where(eid: funding_bodies)
    end

    def map_funding_programs(funding_programs)
      FundingProgram.where(eid: funding_programs)
    end

    private
      def log(msg)
        @logger.call(msg)
      end
  end
end
