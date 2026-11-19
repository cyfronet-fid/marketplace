# frozen_string_literal: true

namespace :service_opinions do
  desc "Recount service_opinion_count and rating of every service, datasources included, from its opinions"
  task repair_counts: :environment do
    logger = Logger.new($stdout)
    Service.find_each do |service|
      count = service.service_opinion_count
      rating = service.rating
      # A counter repair must not run, or be blocked by, the records' validations.
      service.update_columns(ServiceOpinion::Totals.call(service)) # rubocop:disable Rails/SkipsModelValidations
      logger.info "Service #{service.name} (#{service.id}): " \
                  "service_opinion_count #{count} => #{service.service_opinion_count}, " \
                  "rating #{rating.to_s("F")} => #{service.rating.to_s("F")}"
    end
  end
end
