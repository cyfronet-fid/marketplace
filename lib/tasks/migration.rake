# frozen_string_literal: true

namespace :migration do
  desc "Add catalogue prefix to the existing services and providers sources"
  task eids: :environment do
    source_types = [
      { type: ServiceSource, method: "service", level: 3 },
      { type: ProviderSource, method: "provider", level: 2 }
    ].freeze
    ActiveRecord::Base.transaction do
      source_types.each do |hash|
        type = hash[:type]
        puts "Migrating #{type} ids to format {catalogue_id}.{old_id}"
        counter = 0
        not_modified = 0
        type.find_each do |source|
          if source.eid.split(".").size >= hash[:level]
            puts "ID #{source.eid} has a new format, omit."
            not_modified += 1
            next
          end
          catalogue_id = source.send(hash[:method])&.catalogue&.pid
          if catalogue_id.present?
            new_eid = "#{catalogue_id}.#{source.eid}"
            source.update!(eid: new_eid)
            obj = source.send(hash[:method])
            obj.pid = new_eid
            obj.save(validate: false)
            counter += 1
            puts "Successfully updated #{type} with eid: #{new_eid}"
            next
          end
          not_modified += 1
          puts "CatalogueID not found. #{type} #{source.eid} not updated"
        end
        puts "Migrated #{counter} objects of type #{type}. Not modified #{not_modified}"
      end
    end
  end
end
