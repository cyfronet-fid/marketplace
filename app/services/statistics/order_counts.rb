# frozen_string_literal: true

module Statistics
  # The number of Orders of each Service, Datasources included (ADR-0008
  # D15 onwards), which ESS sends as usage_counts_downloads. An Order is a
  # Project item whose order type was "order required" when it was created,
  # internal or external, whatever its status. A Project item keeps that
  # order type, so a later change to its Offer doesn't change past counts.
  # A bundled Project item counts toward the Service of its own Offer.
  # Offers of Deployable Services are left out.
  class OrderCounts < ApplicationService
    def initialize(services)
      super()
      @services = services
    end

    # { service id => Orders }, 0 for a Service without any, in one query.
    # ProjectItem.orderable doesn't fit: it filters on an Offer status that
    # Project items don't have.
    def call
      service_ids = @services.map(&:id)
      counts =
        ProjectItem
        .order_required
        .joins(:offer)
        .where(offers: { orderable_type: Service.polymorphic_name, orderable_id: service_ids })
        .group("offers.orderable_id")
        .count

      service_ids.index_with { |id| counts.fetch(id, 0) }
    end
  end
end
