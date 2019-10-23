# frozen_string_literal: true

namespace :research_areas do
  desc "Move all services with parent research areas to other_for child"
  task migrate_from_parent_research_areas: :environment do
    ResearchArea.transaction do
      parents = ResearchArea.all - ResearchArea.leafs
      parents.each do |ra|
        services = ra.services
        services.each { |service| service.research_areas.delete(ra) }
        services.each do |service|
          service.research_areas << other_for(ra)
          service.save!(validate: false)
        end
      end
    end
  end

  def other_for(research_area)
    ResearchArea.find_by(name: "Other for #{research_area.name.downcase}") ||
        ResearchArea.create(name: "Other for #{research_area.name.downcase}", parent: research_area)
  end
end
