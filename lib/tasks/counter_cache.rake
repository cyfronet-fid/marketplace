# frozen_string_literal: true

desc "Counter cache for categories has many services"
task service_counter: :environment do
  Category.reset_column_information
  Category.pluck(:id).each do |id|
    Category.reset_counters(id, :services)
  end
end
