# frozen_string_literal: true

desc "Generate friendly ids for services and categories"
namespace :friendly_id do
  task generate: :environment do
    Service.find_each(&:save)
    Category.find_each(&:save)
  end

  task heal: :environment do
    Service
      .where(status: "deleted")
      .each do |service|
        puts "Releasing slug #{service.slug} and eid: #{service.pid}"
        service.update(slug: "#{service.slug}_deleted", pid: "#{service.pid}+invalidated", status: "deleted")
      end
    Service.visible.each do |service|
      service.slug = nil
      service.save
      service.reload
      puts "Assigned slug #{service.slug} to #{service.type} #{service.name} #{service.pid}"
    end
  end
end
