# frozen_string_literal: true

namespace :migration do
  desc "Import catalogue info for services and providers"
  task catalogue_data: :environment do
    @faraday = Faraday
    types = [{ clazz: Service, method: "resource" }, { clazz: Provider, method: "provider" }].freeze
    ActiveRecord::Base.transaction do
      types.each do |type|
        token = ENV["MP_IMPORT_TOKEN"] || Importers::Token.new(faraday: @faraday).receive_token
        url = ENV["MP_IMPORT_EOSC_REGISTRY_URL"] || "https://beta.providers.eosc-portal.eu/api"
        type[:clazz].find_each do |obj|
          if obj.pid.blank? && obj.sources.first.blank?
            puts "Object #{obj.name} has no source, omit"
            next
          end
          pid = obj.pid || obj.sources.first&.eid
          r = Importers::Request.new(url, type[:method], faraday: @faraday, token: token, id: pid).call
          b = r.body
          obj.catalogue = Catalogue.find_by(pid: b["catalogueId"])
          obj.save(validate: false)
          puts "Successfully imported #{obj.catalogue.pid} catalogue to the resource #{obj.name} #{pid}"
        rescue Faraday::ParsingError, Errno::ECONNREFUSED, URI::InvalidURIError => e
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

  desc "Migrate datasources ids given by the list"
  task datasource_ids: :environment do
    file = File.read("datasource_ids.json")
    migration_data = JSON.parse(file)
    migration_data.each do |key, value|
      puts "Update old datasource id from #{key} value #{value}"
      source = ServiceSource.find_by(eid: key)
      if source.blank?
        puts "Datasource #{key} not found"
        next
      end
      service = Service.find(source.service_id)
      source.update(eid: value)
      service.update(pid: value)
    end
  end

  desc "Add user_id to Data Administrators"
  task user_id: :environment do
    User.find_each do |user|
      puts "Find data administrators for user #{user.email}"
      administrators = DataAdministrator.where(email: user.email)
      puts "Found #{administrators.size} DataAdministrators. Updating all"
      administrators.update_all(user_id: user.id)
      puts "Updated #{administrators.size} DataAdministrators"
    end
    DataAdministrator.counter_culture_fix_counts
  end
end
