# frozen_string_literal: true

namespace :statuses do
  desc "Test for concurency of threads in the sidekiq queue"

  task migrate_draft: :environment do
    [Catalogue, Provider, Service, Offer].each do |klass|
      puts "Migrating draft statuses for #{klass}"
      klass.where(status: :draft).update_all(status: :unpublished)
      klass.reindex unless klass.name == "Catalogue"
    end
  end
end
