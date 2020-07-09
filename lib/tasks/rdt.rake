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

    puts "Creating life_cycle_statuses from yaml"
    yaml_hash["life_cycle_status"].each do |_, hash|
      LifeCycleStatus.find_or_initialize_by(name: hash["name"]) do |trl|
        trl.update!(name: hash["name"],
                    eid: hash["eid"],
                    description: hash["description"])
      end
      puts "Created trl: #{hash["name"]}"
    end
  end

  desc "Create new targetGroups"

  task add_target_users: :environment do
    research_group = TargetUser.find_by(name: "Research group")
    research_group.update!(name: "Research groups") if research_group.present?
    business = TargetUser.find_by(name: "Business")
    business.update!(name: "Businesses") if business.present?

    create_or_update_target_user("Businesses", "An organization or economic system where goods and services are exchanged for one another or for money. Businesses can be privately owned, not-for-profit or state-owned.",
                                 "target_user-businesses")
    create_or_update_target_user("Research groups", "A research group is a group of researchers working together on a particular issue or topic. Research groups may be composed of researchers all from the same subject/discipline or from different subjects/disciplines.",
                                 "target_user-research_groups")
    create_or_update_target_user("Researchers",
                                 "Someone who conducts scientific research, i.e., an organized and systematic investigation by using scientific methods.",
                                 "target_user-researchers")
    create_or_update_target_user("Providers",
                                 "A Provider is an organisation that provides different kind of solutions and/or services or other Resources to end users and other organizations. This broad term incorporates all businesses and organisations that provide products and solutions that are offered for free, on-demand, pay per use or a hybrid delivery model.",
                                 "target_user-providers")
    create_or_update_target_user("Research organisations",
                                 "A public or private legal entity (e.g. academia, business, industry, public services, etc.) representing the User.",
                                 "target_user-research_organisations")
    create_or_update_target_user("Research communities",
                                 "Research communities provide an infrastructure through which scientists of discipline-specific scientific areas are able to advance their research goals, reaching out to other researchers.",
                                 "target_user-research_communities")
    create_or_update_target_user("Research projects",
                                 "A privately or publicly funded project on a research topic.",
                                 "target_user-research_projects")
    create_or_update_target_user("Research networks",
                                 "Research networks aim to stimulate interaction between researchers and promote information exchange.",
                                 "target_user-research_networks")
    create_or_update_target_user("Research managers",
                                 "Someone in an organization whose job is to manage a research initiative aiming to the development of new scientific results, products or ideas.",
                                 "target_user-research_managers")
    create_or_update_target_user("Students",
                                 "A person who is studying at a university or other place of higher education.",
                                 "target_user-students")
    create_or_update_target_user("Innovators",
                                 "The group or individual which is the first to try new ideas, processes, goods and services. Innovators are followed by early adopters, early majority, late majority, and laggards, in that order.",
                                 "target_user-innovators")
    create_or_update_target_user("Funders",
                                 "Individual or organization financing a part or all of a project's cost as a grant, investment, or loan.",
                                 "target_user-funders")
    create_or_update_target_user("Policy Makers",
                                 "Individuals (usually members of the board of directors) who have the authority to set the policy framework of an organization.",
                                 "target_user-policy_makers")
    create_or_update_target_user("Research Infrastructure Managers",
                                 "A RI Manager is a type of Project Coordinator who specializes in research infrastructures. They are responsible for things like managing researchers, making sure costs are on budget and serving as a liaison between reserach staff and project stakeholders.",
                                 "target_user-research_infrastructure_managers")
    create_or_update_target_user("Provider Managers",
                                 "A Provider Manager is an individual within an organisation that is responsible for the quality of the Resources provided and monitors the delivery of the Resource.",
                                 "target_user-provider_managers")
    create_or_update_target_user("Resource Managers",
                                 "Resource Managers are typically responsible for managing Service level agreements with customers and external Providers.",
                                 "target_user")
    create_or_update_target_user("Other",
                                 "",
                                 "target_user-other")
  end

  def create_or_update_target_user(name, desc, eid)
    target = TargetUser.find_or_initialize_by(name: name)
    target.update!(description: desc, eid: eid)
  end
end
