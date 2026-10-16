# frozen_string_literal: true

namespace :deployable_service do
  desc "Regenerate default offers of deployable services from their TOSCA templates"
  task refresh_default_offers: :environment do
    DeployableService.find_each do |service|
      next unless service.default_offer_template?

      puts "Refreshing default offer for #{service.name}"
      DeployableService::CreateDefaultOffer.call(service)
    end
  end
end
