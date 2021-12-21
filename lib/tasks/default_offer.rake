# frozen_string_literal: true

desc "Make all first offers default"
namespace :default_offer do
  task set: :environment do
    one_offer_services = Service.joins(:offers).where(offers_count: 1)

    one_offer_services.each do |service|
      puts "Updating offer for #{service.name}"
      service.offers.each { |offer| offer.update(default: true) }
    end
  end
end
