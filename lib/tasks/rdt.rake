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

  task add_vocabularies: :environment do
    require "yaml"
    puts "Creating funding bodies from yaml"
    yaml_hash = YAML.load_file("db/vocabulary.yml")

    yaml_hash["funding_body"].each do |_, hash|
      Vocabulary::FundingBody.find_or_initialize_by(eid: hash["eid"]) do |funding_body|
        funding_body.update!(
          name: hash["name"],
          eid: hash["eid"],
          description: hash["description"],
          parent: Vocabulary::FundingBody.find_by(eid: hash["parentId"]),
          extras: hash["extras"]
        )
      end
      puts "Created funding body: #{hash["name"]}"
    end

    puts "Creating funding programs from yaml"
    yaml_hash["funding_program"].each do |_, hash|
      Vocabulary::FundingProgram.find_or_initialize_by(eid: hash["eid"]) do |funding_program|
        funding_program.update!(
          name: hash["name"],
          eid: hash["eid"],
          description: hash["description"],
          parent: Vocabulary::FundingProgram.find_by(eid: hash["parentId"]),
          extras: hash["extras"]
        )
      end
      puts "Created funding program: #{hash["name"]}"
    end

    puts "Creating trls from yaml"
    yaml_hash["trl"].each do |_, hash|
      Vocabulary::Trl.find_or_initialize_by(eid: hash["eid"]) do |trl|
        trl.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
      end
      puts "Created trl: #{hash["name"]}"
    end

    puts "Creating target_users from yaml"
    yaml_hash["target_user"].each do |_, hash|
      existing_target_user = TargetUser.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_target_user.blank?
        TargetUser.find_or_initialize_by(eid: hash["eid"]) do |tu|
          tu.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created target user: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_target_user.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated existing target user: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating life_cycle_statuses from yaml"
    yaml_hash["life_cycle_status"].each do |_, hash|
      lcs = Vocabulary::LifeCycleStatus.find_or_create_by(eid: hash["eid"])
      lcs.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
      puts "Created trl: #{lcs.name}"
    end

    puts "Creating access_types from yaml"
    yaml_hash["access_type"].each do |_, hash|
      Vocabulary::AccessType.find_or_initialize_by(eid: hash["eid"]) do |access_type|
        access_type.update!(
          name: hash["name"],
          eid: hash["eid"],
          description: hash["description"],
          parent: Vocabulary::AccessType.find_by(eid: hash["parentId"]),
          extras: hash["extras"]
        )
      end
      puts "Created access_type: #{hash["name"]}, eid: #{hash["eid"]}"
    end

    puts "Creating access_modes from yaml"
    yaml_hash["access_mode"].each do |_, hash|
      Vocabulary::AccessMode.find_or_initialize_by(eid: hash["eid"]) do |access_mode|
        access_mode.update!(
          name: hash["name"],
          eid: hash["eid"],
          description: hash["description"],
          parent: Vocabulary::AccessMode.find_by(eid: hash["parentId"]),
          extras: hash["extras"]
        )
      end
      puts "Created access_mode: #{hash["name"]}, eid: #{hash["eid"]}"
    end

    puts "Creating categories from yaml"
    yaml_hash["category"].each do |_, hash|
      existing_category = Category.find_by(name: hash["name"], eid: [hash["eid"], nil])
      parent = hash["parentId"].blank? ? nil : Category.find_by(eid: hash["parentId"])
      if existing_category.blank?
        c =
          Category.find_or_initialize_by(eid: hash["eid"]) do |category|
            category.update!(
              name: hash["name"],
              eid: hash["eid"],
              description: hash["description"],
              slug: hash["slug"],
              parent: parent
            )
          end
        puts "Created category: #{c.name}, eid: #{c.eid}, slug: #{c.slug}"
      else
        existing_category.update!(
          name: hash["name"],
          eid: hash["eid"],
          description: hash["description"],
          slug: hash["slug"],
          parent: parent
        )
        puts "Updated existing category: #{existing_category.name}, eid: #{existing_category.eid}, " \
               "slug: #{existing_category.slug}"
      end
    end
    puts "Remove categories with no eid"
    to_remove = Category.where(eid: [nil, ""])
    puts "Removing categories #{to_remove.map(&:name)}"
    to_remove.destroy_all
    puts "Check and repair categories slugs"
    Category
      .where("slug ~* ?", "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
      .each do |category|
        puts "Found category #{category.name} with slug #{category.slug}"
        category.slug = nil
        category.save!
        puts "Category #{category.name} updated with new slug: #{category.slug}"
      end

    puts "Creating scientific_domains from yaml"
    yaml_hash["scientific_domain"].each do |_, hash|
      existing_domain = ScientificDomain.find_by(name: hash["name"], eid: [hash["eid"], nil])
      parent = hash["parentId"].blank? ? nil : ScientificDomain.find_by(eid: hash["parentId"])
      if existing_domain.blank?
        ScientificDomain.find_or_initialize_by(eid: hash["eid"]) do |sd|
          sd.update!(name: hash["name"], eid: hash["eid"], description: hash["description"], parent: parent)
        end
        puts "Created scientific domain: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_domain.update!(name: hash["name"], eid: hash["eid"], description: hash["description"], parent: parent)
        puts "Updated existing scientific domain: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating ESFRI Types from yaml"
    yaml_hash["esfri_type"].each do |hash|
      existing_type = Vocabulary::EsfriType.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_type.blank?
        Vocabulary::EsfriType.find_or_initialize_by(eid: hash["eid"]) do |et|
          et.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created ESFRI Type: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_type.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated ESFRI Type: #{hash["name"]}, eid: #{hash["eid"]}"
      end
    end

    puts "Creating areas of activity from yaml"
    yaml_hash["area_of_activity"].each do |hash|
      existing_area = Vocabulary::AreaOfActivity.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_area.blank?
        Vocabulary::AreaOfActivity.find_or_initialize_by(eid: hash["eid"]) do |aoa|
          aoa.update!(name: hash["name"], eid: hash["eid"])
        end
        puts "Created area of activity: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_area.update!(name: hash["name"], eid: hash["eid"])
        puts "Updated area of activity: #{hash["name"]}, eid: #{hash["eid"]}"
      end
    end

    puts "Creating ESFRI domains from yaml"
    yaml_hash["esfri_domain"].each do |hash|
      existing_category = Vocabulary::EsfriDomain.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_category.blank?
        Vocabulary::EsfriDomain.find_or_initialize_by(eid: hash["eid"]) do |category|
          category.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created ESFRI domain: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_category.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated existing ESFRI domain: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating legal statuses from yaml"
    yaml_hash["provider_legal_status"].each do |hash|
      existing_status = Vocabulary::LegalStatus.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_status.blank?
        Vocabulary::LegalStatus.find_or_initialize_by(eid: hash["eid"]) do |status|
          status.update!(name: hash["name"], eid: hash["eid"])
        end
        puts "Created legal status: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_status.update!(name: hash["name"], eid: hash["eid"])
        puts "Updated existing legal status: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating provider life cycle statuses from yaml"
    yaml_hash["provider_life_cycle_status"].each do |hash|
      existing_plcs = Vocabulary::ProviderLifeCycleStatus.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_plcs.blank?
        Vocabulary::ProviderLifeCycleStatus.find_or_initialize_by(eid: hash["eid"]) do |plcs|
          plcs.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created provider life cycle status: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_plcs.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated existing provider life cycle status: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating meril scientific domains from yaml"
    yaml_hash["meril_scientific_domain"].each do |hash|
      existing_msd = Vocabulary::MerilScientificDomain.find_by(name: hash["name"], eid: [hash["eid"], nil])
      parent = hash["parentId"].blank? ? nil : Vocabulary::MerilScientificDomain.find_by(eid: hash["parentId"])
      if existing_msd.blank?
        Vocabulary::MerilScientificDomain.find_or_initialize_by(eid: hash["eid"]) do |msd|
          msd.update!(name: hash["name"], eid: hash["eid"], description: hash["description"], parent: parent)
        end
        puts "Created meril scientific domain: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_msd.update!(name: hash["name"], eid: hash["eid"], description: hash["description"], parent: parent)
        puts "Updated existing meril scientific domain: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating networks from yaml"
    yaml_hash["network"].each do |hash|
      existing_network = Vocabulary::Network.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_network.blank?
        Vocabulary::Network.find_or_initialize_by(eid: hash["eid"]) do |network|
          network.update!(name: hash["name"], eid: hash["eid"])
        end
        puts "Created network: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_network.update!(name: hash["name"], eid: hash["eid"])
        puts "Updated existing network: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating societal grand challenges from yaml"
    yaml_hash["societal_grand_challenge"].each do |hash|
      existing_challenge = Vocabulary::SocietalGrandChallenge.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_challenge.blank?
        Vocabulary::SocietalGrandChallenge.find_or_initialize_by(eid: hash["eid"]) do |challenge|
          challenge.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created societal grand challenge: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_challenge.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated existing societal grand challenge: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating structure types from yaml"
    yaml_hash["structure_type"].each do |hash|
      existing_type = Vocabulary::StructureType.find_by(name: hash["name"], eid: [hash["eid"], nil])
      if existing_type.blank?
        Vocabulary::StructureType.find_or_initialize_by(eid: hash["eid"]) do |type|
          type.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        end
        puts "Created structure type: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_type.update!(name: hash["name"], eid: hash["eid"], description: hash["description"])
        puts "Updated existing structure type: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end
  end
end
