# frozen_string_literal: true

desc "Generate friendly ids for services and categories"
namespace :friendly_id do
  task generate: :environment do
    Service.find_each(&:save)
    Category.find_each(&:save)
  end
end
