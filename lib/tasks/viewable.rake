# frozen_string_literal: true

namespace :viewable do
  task heal_tags: :environment do
    puts "Heal tag capitalization"
    tags =
      ENV.fetch(
        "HEAL_TAG_LIST",
        "EOSC::Jupyter Notebook,EOSC::Galaxy Workflow,EOSC::Twitter Data,EOSC::Data Cube,EOSC::RO-crate"
      ).split(",")
    tags.each do |tag|
      puts "Healing #{tag}"
      current = ActsAsTaggableOn::Tag.where("LOWER(name) = '#{tag.downcase}'").each { |t| t.update(name: tag) }
      puts "Updated tag #{current.map(&:name)}"
    end
    old = "eosc::egi notebooks"
    puts "change `#{old}` to `EOSC::Jupyter Notebook`"
    Service
      .all
      .select { |s| s.tag_list.map(&:downcase).include?(old) }
      .each do |service|
        puts "Healing tags for #{service.name} #{service.pid}, tag_list: #{service.tag_list}"
        list = service.tag_list.reject { |t| t.downcase == old } << "EOSC::Jupyter Notebook"
        puts "New list: #{list}"
        service.update(tag_list: list)
        service.reload
        puts "Updated service #{service.name} #{service.pid} tags: #{service.tag_list}"
      end
  end
end
