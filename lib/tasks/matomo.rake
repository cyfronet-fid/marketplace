# frozen_string_literal: true

namespace :matomo do
  desc "Sync the Matomo Views of the days FROM to TO (YYYY-MM-DD) into view_statistics, usage_counts_views " \
       "and popularity_ratio"
  task :sync_views, %i[from to] => :environment do |_task, args|
    if args[:from].blank? || args[:to].blank?
      raise ArgumentError, 'Usage: bin/rails "matomo:sync_views[YYYY-MM-DD,YYYY-MM-DD]" (first and last day)'
    end

    dates = Date.iso8601(args[:from])..Date.iso8601(args[:to])
    # Matomo would answer a reversed range with the report of its last day.
    raise ArgumentError, "The first day, #{dates.begin}, is after the last day, #{dates.end}" if dates.begin > dates.end

    matomo = Mp::Application.config.matomo
    abort "Matomo view sync skipped: MP_MATOMO_ENABLED is not true" unless matomo.enabled?
    abort "Matomo view sync skipped: MP_MATOMO_TOKEN_AUTH is not set" if matomo.token_auth.blank?

    Statistics::SyncViews.call(dates:)
  end
end
