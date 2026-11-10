# frozen_string_literal: true

module Statistics
  # Recomputes popularity_ratio of every service, by which Service.popular
  # orders the home page's popular services (ADR-0008 D11): 1000 × (the
  # service's share of all service Views + its share of all project items).
  # A share is 0 while its total is 0. Deployable services keep their fixed
  # popularity_ratio of 0.0.
  class UpdatePopularityRatio < ApplicationService
    def call
      totals = { views: Service.sum(:usage_counts_views), project_items: ProjectItem.count }

      # A ratio derived in bulk, so validations and callbacks don't apply.
      Service.update_all([<<~SQL.squish, totals]) # rubocop:disable Rails/SkipsModelValidations
        popularity_ratio = 1000.0 * (
          COALESCE(usage_counts_views::float / NULLIF(:views, 0), 0) +
          COALESCE(project_items_count::float / NULLIF(:project_items, 0), 0)
        )
      SQL
    end
  end
end
