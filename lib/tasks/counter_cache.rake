# frozen_string_literal: true

desc "Counter cache for services has many offers"
task service_counter: :environment do
  Offer.counter_culture_fix_counts
  ProjectItem.counter_culture_fix_counts
end
