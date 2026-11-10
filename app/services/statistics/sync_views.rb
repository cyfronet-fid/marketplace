# frozen_string_literal: true

module Statistics
  # Reads the daily Views of Services, Providers and Bundles back from Matomo
  # into view_statistics, then recounts usage_counts_views of every service,
  # provider and bundle, copies each service's onto its offers and recomputes
  # popularity_ratio (ADR-0008 D8–D11). It only upserts the requested days, so
  # re-runs over the same days give the same numbers.
  class SyncViews < ApplicationService
    # A kind of record whose View events are named by its PID.
    NamedByPid = Data.define(:model) do
      def ids_by_name(names)
        model.where(pid: names).pluck(:pid, :id).to_h
      end
    end

    # Bundles, which have no PID: their View events are named
    # "<service PID>:<bundle iid>". A service PID may contain ":" itself, so a
    # name is split on its last one.
    NamedByServicePidAndIid = Data.define(:model) do
      def ids_by_name(names)
        pids_and_iids = names.map { |name| name.rpartition(":") }

        model
          .joins(:service)
          .where(services: { pid: pids_and_iids.map(&:first) }, iid: pids_and_iids.map(&:last))
          .pluck("services.pid", :iid, :id)
          .to_h { |pid, iid, id| ["#{pid}:#{iid}", id] }
          .slice(*names)
      end
    end

    VIEWABLES = [NamedByPid.new(Service), NamedByPid.new(Provider), NamedByServicePidAndIid.new(Bundle)].freeze

    def initialize(dates: (Date.current - 2)..Date.current, client: Matomo::ReportingClient.new)
      super()
      @dates = dates
      @client = client
    end

    def call
      rows = statistic_rows(@client.views(@dates))

      ViewStatistic.transaction do
        # Plain counts read from Matomo; ViewStatistic has no validations to skip.
        ViewStatistic.upsert_all(rows, unique_by: :index_view_statistics_on_viewable_and_date) if rows.any? # rubocop:disable Rails/SkipsModelValidations
        VIEWABLES.each { |viewable| recount(viewable.model) }
        copy_service_views_to_offers
        UpdatePopularityRatio.call
      end
    end

    private

    def statistic_rows(view_counts)
      records_by_name = viewables_by_name(view_counts.map(&:name).uniq)

      view_counts.filter_map do |count|
        viewable_type, viewable_id = records_by_name[count.name]
        next unless viewable_id

        { viewable_type:, viewable_id:, date: count.date, views: count.views, visits: count.visits }
      end
    end

    # The report has no event category, so a name is looked up in every kind
    # of viewable record, in VIEWABLES order, and the first kind that knows it
    # gets it. PIDs are unique across kinds, and bundle names come last, so a
    # PID that also reads as "<service PID>:<iid>" still names its own record.
    # Names of no record, such as the PID of a service removed from this Node,
    # are logged and skipped.
    def viewables_by_name(names)
      found =
        VIEWABLES.each_with_object({}) do |viewable, result|
          viewable.ids_by_name(names - result.keys).each do |name, id|
            result[name] = [viewable.model.polymorphic_name, id]
          end
        end

      unknown = names - found.keys
      Rails.logger.warn("Matomo View events of no known record: #{unknown.join(", ")}") if unknown.any?
      found
    end

    # usage_counts_views of every record is the sum of its Views, or 0, so the
    # first sync also clears the values left from the Google Analytics era.
    def recount(model)
      statistics = ViewStatistic.arel_table
      views = ViewStatistic.where(viewable_type: model.polymorphic_name)
                           .where(statistics[:viewable_id].eq(model.arel_table[:id]))
                           .select(statistics[:views].sum)

      set_usage_counts_views(model, views)
    end

    # ESS has always reported a service's views on its offers too.
    def copy_service_views_to_offers
      views = Service.where(Service.arel_table[:id].eq(Offer.arel_table[:orderable_id])).select(:usage_counts_views)

      set_usage_counts_views(Offer.where(orderable_type: Service.polymorphic_name), views)
    end

    # Sets usage_counts_views of every record in records to the value of the
    # correlated views subquery, or 0 when it has none.
    def set_usage_counts_views(records, views)
      # A counter written in bulk, so validations and callbacks don't apply.
      records.update_all("usage_counts_views = COALESCE((#{views.to_sql}), 0)") # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
