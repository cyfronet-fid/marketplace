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
                             parent: FundingBody.find_by(id: hash["parentId"]),
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
                                parent: FundingProgram.find_by(id: hash["parentId"]),
                                extras: hash["extras"])
      end
      puts "Created funding program: #{hash["name"]}"
    end

    puts "Creating trls from yaml"

    yaml_hash["trl"].each do |_, hash|
      Trl.find_or_initialize_by(name: hash["name"]) do |trl|
        trl.update!(name: hash["name"],
                    eid: hash["eid"],
                    description: hash["description"])
      end
      puts "Created trl: #{hash["name"]}"
    end
  end
end
