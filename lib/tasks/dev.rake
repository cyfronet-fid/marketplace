# frozen_string_literal: true

namespace :dev do
  desc "Sample data for local development environment"
  task prime: "db:setup" do
    yaml_hash = YAML.load_file("db/data.yml")

    create_categories(yaml_hash["categories"])
    create_providers(yaml_hash["providers"])
    create_research_areas(yaml_hash["area"])
    create_platforms(yaml_hash["platforms"])
    create_target_groups(yaml_hash["target_groups"])
    create_services(yaml_hash["services"])
    create_relations(yaml_hash["relations"])

    puts "Done!"
  end

  def create_categories(categories_hash)
    puts "Generating categories:"
    categories_hash.each do |_, hash|
      Category.find_or_initialize_by(name: hash["name"]) do |category|
        category.update!(description: hash["description"],
                        parent: Category.find_by(name: hash["parent"]))
        puts "  - #{hash["name"]} category generated"
      end
    end
  end

  def create_providers(providers_hash)
    puts "Generating providers:"
    providers_hash.each do |_, hash|
      Provider.find_or_create_by(name: hash["name"])
      puts "  - #{hash["name"]} provider generated"
    end
  end

  def create_research_areas(research_areas_hash)
    puts "Generating research areas:"
    research_areas_hash.each do |_, hash|
      # !!! Warning: parent need to be defined before child in yaml !!!
      parent = ResearchArea.find_by(name: hash["parent"])
      ResearchArea.find_or_initialize_by(name: hash["name"]) do |ra|
        ra.update!(parent: parent)
      end
      puts "  - #{hash["name"]} research area generated"
    end
  end

  def create_platforms(platforms_hash)
    puts "Generating platforms:"
    platforms_hash.each do |_, hash|
      Platform.find_or_create_by(name: hash["name"])
      puts "  - #{hash["name"]} platforms generated"
    end
  end

  def create_target_groups(target_groups_hash)
    puts "Generating target groups:"
    target_groups_hash.each do |_, hash|
      TargetGroup.find_or_create_by(name: hash["name"])
      puts "  - #{hash["name"]} target group generated"
    end
  end

  def create_services(services_hash)
    puts "Generating services:"
    services_hash.each do |_, hash|
      categories = Category.where(name: hash["parents"])
      providers = Provider.where(name: hash["providers"])
      area = ResearchArea.where(name: hash["area"])
      platforms = Platform.where(name: hash["platforms"])
      target_groups = TargetGroup.where(name: hash["target_groups"])
      service = Service.find_or_initialize_by(title: hash["title"])
      service_type = service_type_from(hash)

      service.update!(tagline: hash["tagline"],
                      description: hash["description"],
                      research_areas: area,
                      providers: providers,
                      service_type: service_type,
                      webpage_url: hash["webpage_url"],
                      manual_url: hash["manual_url"],
                      helpdesk_url: hash["helpdesk_url"],
                      tutorial_url: hash["tutorial_url"],
                      terms_of_use_url: hash["terms_of_use_url"],
                      sla_url: hash["sla_url"],
                      access_policies_url: hash["access_policies_url"],
                      places: hash["places"],
                      languages: hash["languages"],
                      target_groups: target_groups,
                      restrictions: hash["restrictions"],
                      phase: hash["phase"],
                      categories: categories,
                      tag_list: hash["tags"],
                      platforms: platforms,
                      status: :published)

      service.logo.attached? && service.logo.purge_later
      hash["logo"] && service.logo.attach(io: File.open("db/logos/#{hash["logo"]}"), filename: hash["logo"])
      puts "  - #{hash["title"]} service generated"

      create_offers(service, hash["offers"])
    end
  end

  def service_type_from(hash)
    if hash["offers"].blank?
      hash["open_access"] ? "external" : "orderable"
    else
      if hash["external"]
        "external"
      else
        hash["open_access"] ? "open_access" : "orderable"
      end
    end
  end

  def create_offers(service, offers_hash)
    offers_hash && offers_hash.each do |_, h|
      service.offers.create!(name: h["name"],
                            description: h["description"],
                            webpage: h["webpage"],
                            parameters: h["parameters"] || [],
                            offer_type: service.service_type,
                            status: :published)
      puts "    - #{h["name"]} offer generated"
    end
  end

  def create_relations(relations_hash)
    puts "Generating service relations from yaml (remove all relations and crating new one):"
    ServiceRelationship.delete_all

    relations_hash && relations_hash.each do |_, hash|
      source = Service.find_by(title: hash["source"])
      target = Service.find_by(title: hash["target"])
      ServiceRelationship.create!(source: source, target: target)
      if hash["both"]
        ServiceRelationship.create!(source: target, target: source)
        puts "  - Relation from #{target.title} to #{source.title} generated"
      end
      puts "  - Relation from #{source.title} to #{target.title} generated"
    end
  end
end
