# frozen_string_literal: true

require "mini_magick"

class Service::PcCreateOrUpdate
  def initialize(eic_service, eic_base_url, unirest: Unirest)
    @unirest = unirest
    @eic_base_url = eic_base_url
    @eid = eic_service["id"]
    @phase_mapping = {
        "trl-7" => "beta",
        "trl-8" => "production",
        "trl-9" => "production"
    }
    @best_effort_category_mapping = {
        "storage":  Category.find_by!(name: "Storage"),
        "training": Category.find_by!(name: "Training & Support"),
        "security": Category.find_by!(name: "Security & Operations"),
        "analytics": Category.find_by!(name: "Processing & Analysis"),
        "data": Category.find_by!(name: "Data management"),
        "compute": Category.find_by!(name: "Compute"),
        "networking": Category.find_by!(name: "Networking"),
    }.stringify_keys
    @eic_service =  eic_service
    @is_active = @eic_service["active"]
  end

  def call
    service = map_service(@eic_service)

    mapped_service = Service.joins(:sources).find_by("service_sources.source_type": "eic",
                                                     "service_sources.eid": @eid)
    if mapped_service.nil? && @is_active
      service = Service.new(service)
      save_logo(service, @eic_service["symbol"])

      if service.save!
        puts "Created new service: #{service.id}"
        ServiceSource.new(service_id: service.id, source_type: "eic", eid: @eid).save!
        service.offers.create(name: "Offer", description: "#{service.title} Offer",
                               offer_type: "open_access",
                               webpage: service.webpage_url, status: service.status)
      end
      service
    elsif mapped_service && !@is_active
      Service::Draft.new(mapped_service).call
      puts "Draft service: #{mapped_service.id}"
      mapped_service
    else
      save_logo(mapped_service, @eic_service["symbol"])
      mapped_service.update!(service)
      puts "Service with id: #{mapped_service.id} successfully updated"
      mapped_service
    end
  end

  private
    def map_service(data)
      service = { title: data["name"],
                            description: [ReverseMarkdown.convert(data["description"],
                                                                 unknown_tags: :bypass,
                                                                 github_flavored: false),
                                          data["options"],
                                          data["userValue"],
                                          data["userBase"]].join("\n"),
                            tagline: data["tagline"].blank? ? "NO IMPORTED TAGLINE" : data["tagline"],
                            places: map_places(data["places"]["place"]) || "World",
                            languages: data["languages"]["language"] || "English",
                            dedicated_for: [],
                            terms_of_use_url: data["termsOfUse"]["termOfUse"] || "",
                            access_policies_url: data["price"],
                            sla_url: data["serviceLevelAgreement"] || "",
                            webpage_url: data["url"] || "",
                            manual_url: data["userManual"] || "",
                            helpdesk_url: data["helpdesk"] || "",
                            tutorial_url: data["trainingInformation"] || "",
                            phase: map_phase(data["trl"]),
                            service_type: "open_access",
                            status: "published",
                            providers: [map_provider(data["providers"]["provider"])],
                            categories: map_category(data["category"]),
                            research_areas: [research_area_other],
                            version: data["version"] || ""
                }
      service
    end

    def map_provider(prov_eid)
      mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                         "provider_sources.eid": prov_eid)

      if mapped_provider.nil?
        begin
          prov = @unirest.get("#{@eic_base_url}/api/provider/#{prov_eid}",
                              headers: { "Accept" => "application/json" })
        rescue Errno::ECONNREFUSED
          abort("\n Exited with errors - could not connect to #{@eic_base_url}\n")
        end

        if prov.code != 200
          abort("\n Exited with errors - could not fetch data (code: #{prov.code})\n")
        end
        provider  = Provider.create!(name: prov.body["name"])
        ProviderSource.create!(provider_id: provider.id, source_type: "eic", eid: prov_eid)
        puts "Created new provider with id #{provider.id}"
        provider
      else
        mapped_provider
      end
    end

    def save_logo(service, image_url)
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
          logo
        end
      rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, SocketError => e
        puts "\nERROR - there was a problem processing image for #{@eid} #{image_url}: #{e}\n"
      rescue => e
        puts "\nERROR - there was a unexpected problem processing image for #{@eid} #{image_url}: #{e}\n"
      end

      unless logo.nil?
        service.logo.attach(io: logo, filename: @eid, content_type: logo_content_type)
      end
    end

    def map_phase(phase)
      @phase_mapping[phase] || "discovery"
    end

    def map_category(category)
      if @best_effort_category_mapping[category]
        [@best_effort_category_mapping[category]]
      else
        []
      end
    end

    def research_area_other
      ResearchArea.find_by!(name: "Other")
    end

    def map_places(place)
      if place == "WW"
        "World"
      elsif place == "EU"
        "Europe"
      else
        ISO3166::Country.search(place).name
      end
    end
end
