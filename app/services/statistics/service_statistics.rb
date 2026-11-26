# frozen_string_literal: true

module Statistics
  # The Service statistics the Statistics API sends, one hash per Service, in
  # the order given. Datasources are Services too. The figures are all-time
  # and match ESS: the stored counters, and the Orders as
  # usage_counts_downloads (Statistics::OrderCounts, one query for all).
  # Views are nil on a Node that doesn't sync them, where the stored 0 would
  # read as "nobody viewed it".
  class ServiceStatistics < ApplicationService
    def initialize(services, matomo: Mp::Application.config.matomo)
      super()
      @services = services
      @matomo = matomo
    end

    def call
      order_counts = OrderCounts.call(@services)
      views_synced = @matomo.views_synced?

      @services.map do |service|
        {
          pid: service.pid,
          offers_count: service.offers_count,
          service_opinion_count: service.service_opinion_count,
          project_items_count: service.project_items_count,
          usage_counts_views: (service.usage_counts_views if views_synced),
          usage_counts_downloads: order_counts.fetch(service.id)
        }
      end
    end
  end
end
