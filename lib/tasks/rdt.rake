# frozen_string_literal: true

namespace :rdt do
  desc "Repair language_availability data"

  task remove_vocabularies: :environment do
    ServiceVocabulary.delete_all
    ProviderVocabulary.delete_all
    Vocabulary.delete_all
  end

  task repair_language_data: :environment do
    Service.find_each do |service|
      lang_items = []
      service.language_availability.each do |lang|
        if lang.length == 2
          lang_items << lang.upcase
        elsif lang.length > 2
          lang_items << I18nData.languages.key(lang.capitalize)
        end
        service.language_availability = lang_items
        service.save!
      rescue StandardError
        puts "Cannot cast language #{lang} in service #{service.name} to alpha2"
      end
    end
  end

  desc "Create new Vocabularies"

  task add_internal_vocabularies: :environment do
    require "yaml"
    puts "Creating internal marketplace vocabularies"
    yaml_hash = YAML.load_file("db/internal_vocabulary.yml")

    puts "Remove old entries"
    Vocabulary::BundleGoal.destroy_all
    Vocabulary::BundleCapabilityOfGoal.destroy_all

    # Vocabulary::ServiceCategory.where.not(parent: nil).destroy_all
    #
    # puts "Creating service subcategories"

    puts "Creating bundle goals"
    yaml_hash["bundle_goals"].each_value { |hash| Vocabulary::BundleGoal.find_or_create_by(name: hash["name"]) }

    puts "Creating bundle capabilities of goals"
    yaml_hash["bundle_capabilities_of_goals"].each_value do |hash|
      Vocabulary::BundleCapabilityOfGoal.find_or_create_by(name: hash["name"])
    end

    puts "Creating research activities with descriptions"
    yaml_hash["research_activities"].each_value do |hash|
      Vocabulary::ResearchActivity.find_or_create_by(name: hash["name"]).update(
        description: hash["description"],
        eid: hash["eid"]
      )
    end

    puts "Creating subcategories for service type"
    yaml_hash["service_types"].each_value { |hash| create_category_with_children(hash) }
  end

  def create_category_with_children(hash, parent = nil, ancestry_level = 0)
    puts "Create #{hash["name"]} ServiceCategory. #{parent&.name ? "Parent: #{parent.name}, " : ""}" +
           "ancestry_level: #{ancestry_level}, eid: #{hash["eid"]}"
    current = Vocabulary::ServiceCategory.find_or_initialize_by(eid: hash["eid"])
    current.update(name: hash["name"], parent: parent)
    if hash.key?("children")
      hash["children"].each_value { |c_hash| create_category_with_children(c_hash, current, ancestry_level + 1) }
    end
  end

  task add_vocabularies: :environment do
    require "yaml"
    yaml_hash = YAML.load_file("db/vocabulary.yml")

    vocabularies = {
      funding_body: Vocabulary::FundingBody,
      funding_program: Vocabulary::FundingProgram,
      trl: Vocabulary::Trl,
      target_user: TargetUser,
      life_cycle_status: Vocabulary::LifeCycleStatus,
      access_type: Vocabulary::AccessType,
      access_mode: Vocabulary::AccessMode,
      category: Category,
      scientific_domain: ScientificDomain,
      esfri_type: Vocabulary::EsfriType,
      esfri_domain: Vocabulary::EsfriDomain,
      area_of_activity: Vocabulary::AreaOfActivity,
      provider_legal_status: Vocabulary::LegalStatus,
      provider_life_cycle_status: Vocabulary::ProviderLifeCycleStatus,
      meril_scientific_domain: Vocabulary::MerilScientificDomain,
      network: Vocabulary::Network,
      societal_grand_challenge: Vocabulary::SocietalGrandChallenge,
      structure_type: Vocabulary::StructureType,
      hosting_legal_entity: Vocabulary::HostingLegalEntity
    }.freeze

    vocabularies.each do |key, klass|
      key = key.to_s
      puts "Seeding db with #{key.humanize.pluralize}"

      yaml_hash[key].each do |hash|
        existing = klass.find_by(name: hash["name"], eid: [hash["eid"], nil])
        if existing.blank?
          klass.new(eid: hash["eid"]) { |object| assign_and_save!(object, hash) }
          puts "Created #{key.humanize}: #{hash["name"]}, eid: #{hash["eid"]}"
        else
          assign_and_save!(existing, hash)
          puts "Updated existing #{key.humanize}: #{hash["name"]} with eid: #{hash["eid"]}"
        end
      end
      next unless klass == Category
      puts "Remove categories with no eid"
      to_remove = klass.where(eid: [nil, ""])
      puts "Removing categories #{to_remove.map(&:name)}"
      to_remove.destroy_all
      puts "Check and repair categories slugs"
      klass
        .where("slug ~* ?", "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
        .each do |category|
          puts "Found category #{category.name} with slug #{category.slug}"
          category.slug = nil
          category.save!
          puts "Category #{category.name} updated with new slug: #{category.slug}"
        end
    end
  end

  def assign_and_save!(object, hash)
    object.assign_attributes(
      name: hash["name"],
      eid: hash["eid"],
      description: hash["description"],
      parent: object.class.find_by(eid: hash["parentId"])
    )
    object.assign_attributes(extras: hash["extras"]) if object.respond_to?(:extras)
    object.save!
  end
end
