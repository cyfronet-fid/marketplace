# frozen_string_literal: true

namespace :migration do
  desc "Import catalogue info for services and providers"
  task catalogue_data: :environment do
    types = [{ clazz: Service, method: "resource" }, { clazz: Provider, method: "provider" }].freeze
    ActiveRecord::Base.transaction do
      types.each do |type|
        url = (ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api") + "/#{type[:method]}"
        type[:clazz].find_each do |obj|
          r = Faraday.get("#{url}/#{obj.pid}")
          b = JSON.parse(r.body)
          obj.catalogue = Catalogue.find_by(pid: b["catalogueId"])
          obj.save(validate: false)
        rescue JSON::ParserError, URI::InvalidURIError => e
          puts "Object #{obj.name} #{obj.pid} could not be updated, enter Catalogue manually. ERROR: #{e.class} #{e}"
        end
      end
    end
  end

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

  desc "Remove unused services given by list in SERVICES_TO_DELETE env variable"
  task remove_unused_services: :environment do
    to_delete = Array(ENV["SERVICES_TO_DELETE"].split(","))
    return "No services ids to remove" if to_delete.blank?
    ActiveRecord::Base.transaction do
      to_delete.each do |pid|
        s = Service.find_by(pid: pid)
        s.status = :deleted
        s.save(validate: false)
        puts "Service #{s.name} #{s.pid} successfully updated with status DELETED"
      rescue StandardError => e
        puts "Service #{s.name} #{s.pid} couldn't be moved to DELETED. Error: #{e}"
      end
    end
  end
end
