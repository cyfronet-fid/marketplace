# frozen_string_literal: true

require "#{Rails.root}/app/helpers/image_helper"

namespace :dev do
  include ImageHelper

  desc "Sample data for local development environment"
  task prime: "db:setup" do
    create_all_from_path("db/data.yml")
    ImportRor.new.create_dev_ror_data
    puts "Done!"
  end

  desc "Sample data for e2e tests"
  task prime_e2e: "db:setup" do
    create_all_from_path("db/data_e2e.yml")
    puts "Done!"
  end

  def create_all_from_path(path)
    yaml_hash = YAML.load_file(path, aliases: true)

    create_vocabularies
    create_categories(yaml_hash["categories"])
    create_scientific_domains(yaml_hash["domain"])
    create_platforms(yaml_hash["platforms"])
    create_target_users(yaml_hash["target_users"])
    create_catalogues(yaml_hash["catalogues"])
    create_providers(yaml_hash["providers"])
    create_services(yaml_hash["services"])
    create_relations(yaml_hash["relations"])

    OrderingApi::AddSombo.new.call
  end

  def create_categories(categories_hash)
    puts "Generating categories:"
    categories_hash.each_value do |hash|
      Category.find_or_initialize_by(name: hash["name"]) do |category|
        category.update!(description: hash["description"], parent: Category.find_by(name: hash["parent"]))
        puts "  - #{hash["name"]} category generated"
      end
    end
  end

  # rubocop:disable Metrics/AbcSize

  def create_providers(providers_hash)
    puts "Generating providers:"
    Provider.skip_callback :validation, :before, :assign_analytics
    providers_hash.each_value do |hash|
      provider = Provider.find_or_initialize_by(name: hash["name"])
      provider.abbreviation = hash["abbreviation"]
      provider.catalogue = Catalogue.find_by(name: hash["catalogue"])
      provider.website = hash["website"]
      provider.legal_entity = hash["legal_entity"]
      provider.description = hash["description"]
      provider.link_multimedia_urls = hash["multimedia"].map { |h| Link::MultimediaUrl.new(url: h) }
      provider.tag_list = hash["tags"]
      provider.street_name_and_number = hash["street_name_and_number"]
      provider.postal_code = hash["postal_code"]
      provider.city = hash["city"]
      provider.region = hash["region"]
      provider.country = Country.for(hash["country_alpha2"])
      provider.certifications = %w[ISO AES VESA].sample(rand(1..3))
      provider.hosting_legal_entity_string = ["Lorem ipsum", "Test", "Some Entity"].sample(rand(1..3))
      provider.affiliations = ["Affiliation A", "Affiliation test", "Affiliation 1"].sample(rand(1..3))
      provider.national_roadmaps = ["Roadmap 1", "Roadmap 2", "Roadmap 3"].sample(rand(1..3))
      provider.pid = provider.abbreviation
      provider.status = hash["status"]
      assign_sample_associations_to_provider(provider)

      io, extension = ImageHelper.base_64_to_blob_stream(hash["image_base_64"])
      provider.logo.attach(
        io: io,
        filename: provider.pid + extension,
        content_type: "image/#{extension.delete!(".", "")}"
      )

      provider.save(validate: false)
      puts "  - #{hash["name"]} provider generated"
      Provider.set_callback :validation, :before, :assign_analytics
    end
  end

  # rubocop:enable Metrics/AbcSize

  def samples_of(vocabulary, max_size = 3)
    vocabulary.all.sample(rand(1..max_size))
  end

  def assign_sample_associations_to_provider(provider)
    provider.provider_life_cycle_status = Vocabulary::ProviderLifeCycleStatus.all.sample.id
    provider.networks = samples_of(Vocabulary::Network)
    provider.structure_types = samples_of(Vocabulary::StructureType)
    provider.esfri_domains = samples_of(Vocabulary::EsfriDomain)
    provider.esfri_type = Vocabulary::EsfriType.all.sample.id
    provider.meril_scientific_domains = samples_of(Vocabulary::MerilScientificDomain)
    provider.areas_of_activity = samples_of(Vocabulary::AreaOfActivity)
    provider.societal_grand_challenges = samples_of(Vocabulary::SocietalGrandChallenge)
    provider.scientific_domains = samples_of(ScientificDomain)
    provider.legal_status = Vocabulary::LegalStatus.all.sample.id
    provider.participating_countries = samples_of(Country)
    provider.public_contacts = [PublicContact.new(email: "example#{provider.id}@mail.com")]
    provider.data_administrators = [
      DataAdministrator.new(first_name: "John#{provider.id}", last_name: "Doe", email: "example#{provider.id}@mail.com")
    ]

    provider
  end

  def create_scientific_domains(scientific_domains_hash)
    puts "Generating scientific domains:"
    scientific_domains_hash.each_value do |hash|
      # !!! Warning: parent need to be defined before child in yaml !!!
      parent = ScientificDomain.find_by(name: hash["parent"])
      ScientificDomain.find_or_initialize_by(name: hash["name"]) { |sd| sd.update!(parent: parent) }
      puts "  - #{hash["name"]} scientific domain generated"
    end
  end

  def create_platforms(platforms_hash)
    puts "Generating platforms:"
    platforms_hash.each_value do |hash|
      Platform.find_or_create_by(name: hash["name"])
      puts "  - #{hash["name"]} platforms generated"
    end
  end

  def create_target_users(target_users_hash)
    puts "Generating target groups:"
    target_users_hash.each_value do |hash|
      parent = TargetUser.find_by(name: hash["parent"])
      TargetUser.find_or_initialize_by(name: hash["name"]) { |sd| sd.update!(parent: parent) }
      puts "  - #{hash["name"]} target group generated"
    end
  end

  # rubocop:disable Metrics/AbcSize
  def create_services(services_hash)
    puts "Generating services:"
    Service.skip_callback :validation, :before, :assign_analytics
    services_hash.each_value do |hash|
      prov = hash["providers"] || []
      categories = Category.where(name: hash["parents"])
      resource_organisation = Provider.find_by(name: hash["resource_organisation"] || prov.shift)
      providers = Provider.where(name: prov)
      catalogue = Catalogue.find_by(name: hash["catalogue"] || [])
      domain = ScientificDomain.where(name: hash["domain"])
      platforms = Platform.where(name: hash["platforms"])
      funding_bodies = Vocabulary::FundingBody.where(eid: hash["funding_bodies"])
      funding_programs = Vocabulary::FundingProgram.where(eid: hash["funding_programs"])
      service = Service.find_or_initialize_by(name: hash["name"])
      trl = Vocabulary::Trl.where(eid: hash["trl"])
      life_cycle_status = Vocabulary::LifeCycleStatus.where(eid: hash["life_cycle_status"])
      target_users = TargetUser.where(name: hash["target_users"])
      public_contacts = [PublicContact.new(email: "mail@example.org")]
      main_contact = MainContact.new(first_name: "John", last_name: "Doe", email: "john@example.org")

      service.assign_attributes(
        pid: hash["pid"] || nil,
        tagline: hash["tagline"],
        description: hash["description"],
        scientific_domains: domain,
        providers: providers,
        catalogue: catalogue,
        order_type: order_type_from(hash),
        order_url: hash["order_url"] || "",
        resource_organisation: resource_organisation,
        webpage_url: hash["webpage_url"],
        manual_url: hash["manual_url"],
        helpdesk_url: hash["helpdesk_url"],
        training_information_url: hash["training_information_url"],
        funding_bodies: funding_bodies,
        funding_programs: funding_programs,
        terms_of_use_url: hash["terms_of_use_url"],
        resource_level_url: hash["resource_level_url"],
        access_policies_url: hash["access_policies_url"],
        language_availability: hash["language_availability"],
        geographical_availabilities: [hash["geographical_availabilities"]],
        target_users: target_users,
        restrictions: hash["restrictions"],
        trls: trl,
        life_cycle_statuses: life_cycle_status,
        categories: categories,
        tag_list: hash["tags"],
        platforms: platforms,
        main_contact: main_contact,
        public_contacts: public_contacts,
        status: hash["status"] || :published
      )
      service.save(validate: false)

      service.logo.attached? && service.logo.purge_later
      hash["logo"] && service.logo.attach(io: File.open("db/logos/#{hash["logo"]}"), filename: hash["logo"])
      puts "  - #{hash["name"]} service generated"

      create_offers(service, hash["offers"])
      Service.set_callback :validation, :before, :assign_analytics
    end
  end

  # rubocop:enable Metrics/AbcSize

  def order_type_from(hash)
    if hash["external"]
      "order_required"
    else
      hash["open_access"] ? "open_access" : "order_required"
    end
  end

  def create_offers(service, offers_hash)
    offers_hash&.each_value do |h|
      effective_order_url = h["order_url"] || service.order_url
      service.offers.create!(
        name: h["name"],
        description: h["description"],
        parameters: Parameter::Array.load(h["parameters"] || []),
        order_type: h["order_type"].blank? ? service.order_type : h["order_type"],
        order_url: effective_order_url.present? ? effective_order_url : "",
        internal: effective_order_url.blank?,
        offer_category:
          service.service_categories.first || Vocabulary::ServiceCategory.find_by(eid: "service_category-other"),
        status: :published
      )
      puts "    - #{h["name"]} offer generated"
    end
  end

  def create_relations(relations_hash)
    puts "Generating service relations from yaml (remove all relations and crating new one):"
    ServiceRelationship.delete_all

    relations_hash&.each_value do |hash|
      source = Service.find_by(name: hash["source"])
      target = Service.find_by(name: hash["target"])
      ManualServiceRelationship.create!(source: source, target: target)
      if hash["both"]
        ManualServiceRelationship.create!(source: target, target: source)
        puts "  - Relation from #{target.name} to #{source.name} generated"
      end
      puts "  - Relation from #{source.name} to #{target.name} generated"
    end
  end

  def create_vocabularies
    Rake::Task["rdt:add_vocabularies"].invoke
    Rake::Task["rdt:add_internal_vocabularies"].invoke
  end

  # rubocop:disable Metrics/AbcSize
  def create_catalogues(catalogue_hash)
    puts "Generating catalogue:"
    catalogue_hash.each_value do |hash|
      catalogue = Catalogue.find_or_initialize_by(name: hash["name"])
      catalogue.pid = hash["pid"]
      catalogue.abbreviation = hash["abbreviation"]
      catalogue.description = hash["description"]
      catalogue.website = hash["website"]
      catalogue.legal_entity = hash["legal_entity"]
      catalogue.scientific_domains = ScientificDomain.where(name: hash["domains"])
      catalogue.participating_countries = hash["participating_countries"]&.map { |c| Country.for(c) }
      catalogue.affiliations = hash["affiliations"]
      catalogue.networks = Vocabulary::Network.where(eid: hash["networks"])
      catalogue.legal_statuses = Vocabulary::LegalStatus.where(eid: hash["legal_statuses"])
      catalogue.hosting_legal_entities = Vocabulary::HostingLegalEntity.where(eid: hash["hosting_legal_entities"])
      catalogue.tags = hash["tags"]
      catalogue.street_name_and_number = hash["street"]
      catalogue.postal_code = hash["postal_code"]
      catalogue.city = hash["city"]
      catalogue.region = hash["region"]
      catalogue.country = Country.for(hash["country_alpha2"])
      catalogue.main_contact = MainContact.new(first_name: "John", last_name: "Doe", email: "john@example.org")
      catalogue.public_contacts = [PublicContact.new(email: "example#{catalogue.id}@mail.com")]
      catalogue.link_multimedia_urls = hash["multimedia"].map { |h| Link::MultimediaUrl.new(url: h) }
      catalogue.end_of_life = hash["end_of_life"]
      catalogue.validation_process = hash["validation_process"]
      catalogue.inclusion_criteria = hash["inclusion_criteria"]

      io, extension = ImageHelper.base_64_to_blob_stream(hash["image_base_64"])
      catalogue.logo.attach(
        io: io,
        filename: catalogue.pid + extension,
        content_type: "image/#{extension.delete!(".", "")}"
      )

      catalogue.save(validate: false)
      puts "  - #{hash["name"]} catalogue generated"
    end
  end
  # rubocop:enable Metrics/AbcSize
end
