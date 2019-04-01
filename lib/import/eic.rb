# frozen_string_literal: true

module Import
  class EIC
    def initialize(eic_base_url, dry_run = true, dont_create_providers = true, unirest = Unirest)
      @eic_base_url = eic_base_url
      @dry_run = dry_run
      @unirest = unirest
      @dont_create_providers = dont_create_providers

      @phase_mapping = {
          "trl-7" => "beta",
          "trl-8" => "production",
          "trl-9" => "production"
      }
    end

    def call
      puts "Importing services from eInfraCentral..."

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

      categories = []

      updated = 0
      created = 0
      not_modified = 0
      total_service_count = r.body["results"].length

      puts "EIC - all services #{total_service_count}"

      r.body["results"].each do |service|
        eid = service["id"]
        url = service["url"]
        order_url = service["order"]
        user_manual_url = service["userManual"]
        training_information_url = service["trainingInformation"]
        helpdesk_url = service["helpdesk"]
        feedback_url = service["feedback"]
        price_url = service["price"]
        service_level_agreement_url = service["serviceLevelAgreement"]
        terms_of_use = service["termsOfUse"] # list

        name = service["name"]
        tagline = service["tagline"]
        description = ReverseMarkdown.convert(service["description"], unknown_tags: :bypass, github_flavored: false)
        options = service["options"]
        target_users = service["targetUsers"]
        user_value = service["userValue"]
        user_base = service["userBase"]
        image_url = service["symbol"]
        last_update = service["lastUpdate"]
        change_log = service["changeLog"]
        category = service["category"]
        subcategory = service["subcategory"]
        tags = service["tags"]
        places = service["places"]
        place_names = service["placeNames"]
        languages = service["languages"]
        language_names = service["languageNames"]
        category = service["category"]
        category_name = service["categoryName"]
        subcategory_name = service["subCategoryName"]
        phase = service["trl"]
        provider_eid = service["providers"][0]


        aggregated_description = [description, options, user_value, user_base].join("\n")

        # Get Provider or create new
        mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                           "provider_sources.eid": provider_eid)
        if mapped_provider.nil?
          if @dont_create_providers
            puts "[WARNING] No mapping for eic provider '#{provider_eid}', skipping service #{name}, #{eid}"
            next
          else
            puts "No mapped provider '#{provider_eid}', creating..."
            unless @dry_run
              mapped_provider = Provider.new(name: @providers[provider_eid]["name"])
              mapped_provider.save
              ProviderSource.new(provider_id: mapped_provider.id, source_type: "eic", eid: provider_eid).save
            end
          end
        end

        updated_service_data = {
            title: name,
            description: aggregated_description,
            tagline: tagline.blank? ? "NO IMPORTED TAGLINE" : tagline,
            connected_url: url || "",
            # provider_id: ?
            # contact_emails: ?
            places: place_names[0] || "World",
            languages: language_names[0] || "English",
            dedicated_for: [],
            terms_of_use_url: terms_of_use[0] || "",
            access_policies_url: price_url,
            corporate_sla_url: service_level_agreement_url || "",
            webpage_url: url || "",
            manual_url: user_manual_url || "",
            helpdesk_url: helpdesk_url || "",
            tutorial_url: training_information_url || "",
            phase: map_phase(phase),
            service_type: "open_access",
            status: "draft",
            providers: [mapped_provider],
            categories: map_category(category),
            research_areas: [@research_area_other]
        }

        if (service_source = ServiceSource.find_by(eid: eid, source_type: "eic")).nil?
          created += 1
          puts "Adding [NEW] service: #{name}, eid: #{eid}"
          unless @dry_run
            service = Service.new(updated_service_data)
            service.save!
            ServiceSource.new(service_id: service.id, eid: eid, source_type: "eic").save!
          end
        else
          service = Service.find_by(id: service_source.service_id)
          if service.upstream_id == service_source.id
            updated += 1
            puts "Updating [EXISTING] service #{service.title}, id: #{service_source.id}, eid: #{eid}"
            unless @dry_run
              service.update!(updated_service_data.except(:research_areas, :categories))
            end
          else
            not_modified += 1
            puts "Service's upstream is not set to EIC, not updating #{service.title}, id: #{service_source.id}"
          end
        end
      end
      puts "PROCESSED: #{total_service_count}, CREATED: #{created}, UPDATED: #{updated}, NOT MODIFIED: #{not_modified}"
    end

    def map_category(category)
      if @best_effort_category_mapping[category]
        [@best_effort_category_mapping[category]]
      else
        []
      end
    end

    def get_db_dependencies
      @research_area_other = ResearchArea.find_by!(name: "Other")

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

    def map_phase(phase)
      @phase_mapping[phase] || "discovery"
    end
  end
end
