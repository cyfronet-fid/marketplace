# frozen_string_literal: true

desc "Counter cache for services has many offers"
task service_counter: :environment do
  Service.reset_column_information
  Service.pluck(:id).each do |id|
    Service.reset_counters(id, :offers)
  end
end

desc "Counter cache for user has many active affiliations"
task active_affiliation_counter: :environment do
  Affiliation.counter_culture_fix_counts
end
