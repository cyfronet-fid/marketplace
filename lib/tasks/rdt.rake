# frozen_string_literal: true

namespace :rdt do
  desc "Repair language_availability data"

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
      FundingBody.find_or_initialize_by(eid: hash["eid"]) do |funding_body|
        funding_body.update!(name: hash["name"],
                             eid: hash["eid"],
                             description: hash["description"],
                             parent: FundingBody.find_by(eid: hash["parentId"]),
                             extras: hash["extras"])
      end
      puts "Created funding body: #{hash["name"]}"
    end

    puts "Creating funding programs from yaml"
    yaml_hash["funding_program"].each do |_, hash|
      FundingProgram.find_or_initialize_by(eid: hash["eid"]) do |funding_program|
        funding_program.update!(name: hash["name"],
                                eid: hash["eid"],
                                description: hash["description"],
                                parent: FundingProgram.find_by(eid: hash["parentId"]),
                                extras: hash["extras"])
      end
      puts "Created funding program: #{hash["name"]}"
    end

    puts "Creating trls from yaml"
    yaml_hash["trl"].each do |_, hash|
      Trl.find_or_initialize_by(eid: hash["eid"]) do |trl|
        trl.update!(name: hash["name"],
                    eid: hash["eid"],
                    description: hash["description"])
      end
      puts "Created trl: #{hash["name"]}"
    end

    puts "Creating target_users from yaml"
    yaml_hash["target_user"].each do |_, hash|
      existing_target_user = TargetUser.find_by(name: hash["name"], eid:  [hash["eid"], nil])
      if existing_target_user.blank?
        TargetUser.find_or_initialize_by(eid: hash["eid"]) do |tu|
          tu.update!(name: hash["name"],
                     eid: hash["eid"],
                     description: hash["description"])
        end
        puts "Created target user: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_target_user.update!(name: hash["name"],
                                eid: hash["eid"],
                                description: hash["description"])
        puts "Updated existing target user: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating life_cycle_statuses from yaml"
    yaml_hash["life_cycle_status"].each do |_, hash|
      lcs = LifeCycleStatus.find_or_create_by(eid: hash["eid"])
      lcs.update!(name: hash["name"],
                  eid: hash["eid"],
                  description: hash["description"])
      puts "Created trl: #{lcs.name}"
    end

    puts "Creating access_types from yaml"
    yaml_hash["access_type"].each do |_, hash|
      AccessType.find_or_initialize_by(eid: hash["eid"]) do |access_type|
        access_type.update!(name: hash["name"],
                            eid: hash["eid"],
                            description: hash["description"],
                            parent: AccessType.find_by(eid: hash["parentId"]),
                            extras: hash["extras"])
      end
      puts "Created access_type: #{hash["name"]}, eid: #{hash["eid"]}"
    end

    puts "Creating access_modes from yaml"
    yaml_hash["access_mode"].each do |_, hash|
      AccessMode.find_or_initialize_by(eid: hash["eid"]) do |access_mode|
        access_mode.update!(name: hash["name"],
                            eid: hash["eid"],
                            description: hash["description"],
                            parent: AccessMode.find_by(eid: hash["parentId"]),
                            extras: hash["extras"])
      end
      puts "Created access_mode: #{hash["name"]}, eid: #{hash["eid"]}"
    end

    puts "Creating categories from yaml"
    yaml_hash["category"].each do |_, hash|
      existing_category = Category.find_by(name: hash["name"], eid: [hash["eid"], nil])
      parent = hash["parentId"].blank? ? nil : Category.find_by(eid: hash["parentId"])
      if existing_category.blank?
        Category.find_or_initialize_by(eid: hash["eid"]) do |category|
          category.update!(name: hash["name"],
                           eid: hash["eid"],
                           description: hash["description"],
                           parent: parent)
        end
        puts "Created category: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_category.update!(name: hash["name"],
                                   eid: hash["eid"],
                                   description: hash["description"],
                                   parent: parent)
        puts "Updated existing category: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end

    puts "Creating scientific_domains from yaml"
    yaml_hash["scientific_domain"].each do |_, hash|
      existing_domain = ScientificDomain.find_by(name: hash["name"], eid:  [hash["eid"], nil])
      parent = hash["parentId"].blank? ? nil : ScientificDomain.find_by(eid: hash["parentId"])
      if existing_domain.blank?
        ScientificDomain.find_or_initialize_by(eid: hash["eid"]) do |sd|
          sd.update!(name: hash["name"],
                           eid: hash["eid"],
                           description: hash["description"],
                           parent: parent)
        end
        puts "Created scientific domain: #{hash["name"]}, eid: #{hash["eid"]}"
      else
        existing_domain.update!(name: hash["name"],
                 eid: hash["eid"],
                 description: hash["description"],
                 parent: parent)
        puts "Updated existing scientific domain: #{hash["name"]} with eid: #{hash["eid"]}"
      end
    end
  end
end
