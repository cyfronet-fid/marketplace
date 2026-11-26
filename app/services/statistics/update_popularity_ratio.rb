# frozen_string_literal: true

module Statistics
  # Recomputes popularity_ratio of every service, by which Service.popular
  # orders the home page's popular services (ADR-0007 D11): 1000 × (the
  # service's share of all service Views + its share of all project items).
  # A share is 0 while its total is 0. Deployable services keep their fixed
  # popularity_ratio of 0.0.
  class UpdatePopularityRatio < ApplicationService
    def call
      # The totals are subqueries of the UPDATE, so they read the same
      # snapshot as the counters of each service.
      views = Service.select(Service.arel_table[:usage_counts_views].sum).to_sql
      project_items = ProjectItem.select(Arel.star.count).to_sql

      # A ratio derived in bulk, so validations and callbacks don't apply.
      Service.update_all(<<~SQL.squish) # rubocop:disable Rails/SkipsModelValidations
        popularity_ratio = 1000.0 * (
          COALESCE(usage_counts_views::float / NULLIF((#{views}), 0), 0) +
          COALESCE(project_items_count::float / NULLIF((#{project_items}), 0), 0)
        )
      SQL
    end
  end
end
