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

      r.body["results"].select { |_r| @ids.empty? || @ids.include?(_r["service"]["id"]) }
          .each do |service_data|
        service = service_data["service"]
        eid = service["id"]
        output.append(service_data)
        # TODO this should be moved to Offer.webpage
        url = service["webpage"]
        # order_url = service["order"]
        user_manual_url = service["userManual"]
        training_information_url = service["trainingInformation"]
        status_monitoring_url = service["statusMonitoring"]
        maintenance_url = service["maintenance"]
        order_url = service["order"]
        payment_model_url = service["paymentModel"]
        pricing_url = service["pricing"]
        multimedia = Array(service["multimedia"]) || []
        use_cases_url = service["useCases"]
        privacy_policy_url = service["privacyPolicy"]
        access_policy_url = service["accessPolicy"]
        helpdesk_url = service["helpdeskPage"]
        service_level_agreement_url = service["serviceLevel"]
        terms_of_use = service["termsOfUse"]
        name = service["name"]
        tagline = service["tagline"]
        description = ReverseMarkdown.convert(service["description"], unknown_tags: :bypass, github_flavored: false)
        image_url = service["logo"]
        last_update = service["lastUpdate"]
        changelog = Array(service["changeLog"])
        certifications = service["certifications"]
        standards = service["standards"]
        open_source_technologies = service["openSourceTechnologies"]
        grant_project_names = service["grantProjectNames"]
        tag_list = Array(service["tags"])
        language_availability = service["languageAvailabilities"] || ["EN"]
        geographical_availabilities = service["geographicalAvailabilities"] ||
        resource_geographic_locations = Array(service["resourceGeographicLocations"]) || []
        categories = service["subcategories"]
        related_platforms = service["relatedPlatforms"] || []
        scientific_domains = service["scientificSubdomains"]
        funding_bodies = service["fundingBody"]
        funding_programs = Array(service["fundingPrograms"])
        main_contact = MainContact.new(map_contact(service["mainContact"])) if service["mainContact"] || nil
        public_contacts = Array(service["publicContacts"])&.map { |c| PublicContact.new(map_contact(c)) } || []
        access_types = service["accessTypes"]
        access_modes = service["accessModes"]
        # category_name = service["categoryName"]
        # subcategory_name = service["subCategoryName"]
        required_services = service["requiredResources"]
        related_services = service["relatedResources"]
        trl = service["trl"]
        life_cycle_status = service["lifeCycleStatus"]
        resource_organisation_eid = service["resourceOrganisation"]
        provider_eids = service["resourceProviders"] || []
        version = service["version"]
        target_users = service["targetUsers"]
        synchronized_at = service_data["metadata"]["modifiedAt"].to_i

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
            if logo_content_type.start_with?("image")
              logo = StringIO.new
              logo.write(img.to_blob)
              logo.seek(0)
              logo_content_type = "image/png"
            end
          end
        rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, SocketError => e
          log "ERROR - there was a problem processing image for #{eid} #{image_url}: #{e}"
        rescue => e
          log "ERROR - there was a unexpected problem processing image for #{eid} #{image_url}: #{e}"
        end


        mapped_resource_organisation =  map_providers([resource_organisation_eid], @providers, name, eid)
        mapped_providers = map_providers(provider_eids, @providers, name, eid)

        updated_service_data = {
            name: name,
            description: description,
            tagline: tagline.blank? ? "NO IMPORTED TAGLINE" : tagline,
            # provider_id: ?
            tag_list: tag_list,
            language_availability: language_availability || ["EN"],
            geographical_availabilities: geographical_availabilities || [],
            resource_geographic_locations: resource_geographic_locations,
            target_users: map_target_users(target_users),
            multimedia: multimedia,
            use_cases_url: use_cases_url,
            access_policies_url: access_policy_url,
            privacy_policy_url: privacy_policy_url,
            terms_of_use_url: terms_of_use || "",
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
            main_contact: main_contact,
            public_contacts: public_contacts,
            trl: Trl.where(eid: trl),
            required_services: map_related_services(required_services),
            related_services: map_related_services(related_services),
            life_cycle_status: LifeCycleStatus.where(eid: life_cycle_status),
            order_type: "open_access",
            status: "draft",
            funding_bodies: map_funding_bodies(funding_bodies),
            funding_programs: map_funding_programs(funding_programs),
            access_types: map_access_types(access_types),
            access_modes: map_access_modes(access_modes),
            resource_organisation: mapped_resource_organisation[0],
            providers: mapped_providers,
            related_platforms: related_platforms,
            pc_categories: map_pc_categories(categories),
            scientific_domains: map_scientific_domains(scientific_domains),
            version: version || "",
            synchronized_at: Time.at(synchronized_at&./1000),
            last_update: last_update.blank? ? nil : Time.at(last_update&./1000),
            changelog: changelog,
            certifications: Array(certifications),
            standards: Array(standards),
            grant_project_names: Array(grant_project_names),
            open_source_technologies: Array(open_source_technologies)
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

    def map_pc_categories(categories)
      PcCategory.where(eid: categories)
    end

    def map_scientific_domains(domains)
      ScientificDomain.where(eid: domains)
    end

    def map_related_services(services)
      Service.joins(:sources).where("service_sources.source_type": "eic",
                                    "service_sources.eid": services)
    end

    def map_contact(contact)
      contact&.transform_keys { |k| k.to_s.underscore } || nil
    end

    def map_funding_bodies(funding_bodies)
      FundingBody.where(eid: funding_bodies)
    end

    def map_funding_programs(funding_programs)
      FundingProgram.where(eid: funding_programs)
    end

    def map_access_types(access_types)
      AccessType.where(eid: access_types)
    end

    def map_access_modes(aceess_modes)
      AccessMode.where(eid: aceess_modes)
    end

    private
      def log(msg)
        @logger.call(msg)
      end
  end
end
