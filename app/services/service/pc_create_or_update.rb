# frozen_string_literal: true

require "mini_magick"

class Service::PcCreateOrUpdate
  class ConnectionError < StandardError
    def initialize(msg)
      super(msg)
    end
  end

  def initialize(eic_service,
                 eic_base_url,
                 is_active,
                 modified_at,
                 unirest: Unirest)
    @unirest = unirest
    @eic_base_url = eic_base_url
    @eid = eic_service["id"]
    @eic_service =  eic_service
    @is_active = is_active
    @modified_at = modified_at
  end

  def call
    service = map_service(@eic_service)
    mapped_service = Service.joins(:sources).find_by("service_sources.source_type": "eic",
                                                     "service_sources.eid": @eid)
    # The latest update from PC is now nil, we have to temporary disable this check
    the_latest_update = true # mapped_service ? (@modified_at > mapped_service.last_update) : true

    if mapped_service.nil? && @is_active
      service = Service.new(service)
      save_logo(service, @eic_service["logo"])

      if service.save!
        ServiceSource.create!(service_id: service.id, source_type: "eic", eid: @eid)
        service.offers.create!(name: "Offer", description: "#{service.name} Offer",
                               order_type: "open_access",
                               webpage: service.webpage_url, status: service.status)
      end
      service
    elsif the_latest_update
      if mapped_service && !@is_active
        Service::Draft.new(mapped_service).call
        mapped_service
      else
        save_logo(mapped_service, @eic_service["logo"])
        mapped_service.update!(service)
        mapped_service
      end
    else
      mapped_service
    end
  end

  private
    def map_service(data)
      main_contact = MainContact.new(map_contact(data["mainContact"])) if data["mainContact"] || nil
      providers = Array(data.dig("resourceProviders", "resourceProvider")) - [data["resourceOrganisation"]]

      { name: data["name"],
        description: ReverseMarkdown.convert(data["description"],
                                             unknown_tags: :bypass,
                                             github_flavored: false),
        tagline: data["tagline"].blank? ? "NO IMPORTED TAGLINE" : data["tagline"],
        tag_list: Array(data.dig("tags", "tag")) || [],
        language_availability: Array(data.dig("languageAvailabilities", "languageAvailability")).
            map { |lang| lang.upcase } || ["EN"],
        geographical_availabilities: Array(data.dig("geographicalAvailabilities", "geographicalAvailability") || "WW"),
        resource_geographic_locations: Array(data.dig("resourceGeographicLocations", "resourceGeographicLocation")) || [],
        target_users: Array(map_target_users(data.dig("targetUsers", "targetUser"))) || [],
        main_contact: main_contact,
        public_contacts: Array.wrap(data.dig("publicContacts", "publicContact")).
            map { |c| PublicContact.new(map_contact(c)) } || [],
        privacy_policy_url: data["privacyPolicy"] || "",
        use_cases_url: Array(data.dig("useCases", "useCase") || []),
        multimedia: Array(data.dig("multimedia", "multimedia")) || [],
        terms_of_use_url: data["termsOfUse"] || "",
        access_policies_url: data["accessPolicy"],
        sla_url: data["serviceLevel"] || "",
        webpage_url: data["webpage"] || "",
        manual_url: data["userManual"] || "",
        helpdesk_url: data["helpdeskPage"] || "",
        helpdesk_email: data["helpdeskEmail"] || "",
        security_contact_email: data["securityContactEmail"] || "",
        training_information_url: data["trainingInformation"] || "",
        status_monitoring_url: data["statusMonitoring"] || "",
        maintenance_url: data["maintenance"] || "",
        order_url: data["order"] || "",
        payment_model_url: data["paymentModel"] || "",
        pricing_url: data["pricing"] || "",
        trl: Trl.where(eid: data["trl"]),
        required_services: map_related_services(Array(data.dig("requiredResources", "requiredResource"))),
        related_services: map_related_services(Array(data.dig("relatedResources", "relatedResource"))),
        life_cycle_status: LifeCycleStatus.where(eid: data["lifeCycleStatus"]),
        access_types: AccessType.where(eid: Array(data.dig("accessTypes", "accessType"))),
        access_modes: AccessMode.where(eid: Array(data.dig("accessModes", "accessMode"))),
        order_type: "open_access",
        status: "published",
        funding_bodies: map_funding_bodies(data.dig("fundingBody", "fundingBody")),
        funding_programs: map_funding_programs(data.dig("fundingPrograms", "fundingProgram")),
        changelog: Array(data.dig("changeLog", "changeLog")),
        certifications: Array(data.dig("certifications", "certification")),
        standards: Array(data.dig("standards", "standard")),
        open_source_technologies: Array(data.dig("openSourceTechnologies", "openSourceTechnology")),
        grant_project_names: Array(data.dig("grantProjectNames", "grantProjectName")),
        resource_organisation: map_provider(data["resourceOrganisation"]),
        providers: providers.map { |p| map_provider(p) },
        related_platforms: Array(data.dig("relatedPlatforms", "relatedPlatform")) || [],
        pc_categories: Array(map_pc_categories(data.dig("subcategories", "subcategory"))) || [],
        scientific_domains: Array(map_scientific_domains(data.dig("scientificSubdomains", "scientificSubdomain"))),
        version: data["version"] || "",
        last_update: data["lastUpdate"]
      }
    end

    def map_target_users(target_users)
      TargetUser.where(eid: target_users)
    end

    def map_provider(prov_eid)
      mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                         "provider_sources.eid": prov_eid)
      if mapped_provider.nil?
        prov = @unirest.get("#{@eic_base_url}/api/provider/#{prov_eid}",
                            headers: { "Accept" => "application/json" })

        if prov.code != 200
          raise Service::PcCreateOrUpdate::ConnectionError
            .new("Cannot connect to: #{@eic_base_url}. Received status #{prov.code}")
        end

        provider  = Provider.find_or_create_by(name: prov.body["name"])
        ProviderSource.create!(provider_id: provider.id, source_type: "eic", eid: prov_eid)
        provider
      else
        mapped_provider
      end
    end

    def save_logo(service, image_url)
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
      if !logo.blank? && logo_content_type.start_with?("image")
        service.logo.attach(io: logo, filename: @eid, content_type: logo_content_type)
      end
    rescue OpenURI::HTTPError => e
      Rails.logger.warn "WARN: Cannot attach logo. #{e.message}"
    end

    def map_pc_categories(categories)
      PcCategory.where(eid: categories)
    end

    def map_scientific_domains(domains)
      ScientificDomain.where(eid: domains)
    end

    def map_contact(contact)
      contact&.transform_keys { |k| k.to_s.underscore } || nil
    end

    def map_related_services(services)
      Service.joins(:sources).where("service_sources.source_type": "eic",
                              "service_sources.eid": services)
    end

    def map_funding_bodies(funding_bodies)
      FundingBody.where(eid: funding_bodies)
    end

    def map_funding_programs(funding_programs)
      FundingProgram.where(eid: funding_programs)
    end

    def scientific_domain_other
      ScientificDomain.find_by!(name: "Other")
    end
end
