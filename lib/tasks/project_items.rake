# frozen_string_literal: true

namespace :project_items do
  desc "Recount project_items_count on services, offers and bundles"
  task repair_counts: :environment do
    logger = Logger.new($stdout)
    [Service, Offer, Bundle].each do |model|
      model
        .includes(:project_items)
        .find_each do |object|
          previous = object.project_items_count
          # A counter repair must not run, or be blocked by, the records' validations.
          object.update_columns(project_items_count: object.project_items.size) # rubocop:disable Rails/SkipsModelValidations
          logger.info "#{object.class} #{object.name} (#{object.id}): #{previous} => #{object.project_items_count}"
        end
    end
  end
end
