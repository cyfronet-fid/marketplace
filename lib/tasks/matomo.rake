# frozen_string_literal: true

namespace :matomo do
  desc "Sync the Matomo Views of the days FROM to TO (YYYY-MM-DD) into view_statistics, usage_counts_views " \
       "and popularity_ratio"
  task :sync_views, %i[from to] => :environment do |_task, args|
    if args[:from].blank? || args[:to].blank?
      raise ArgumentError, 'Usage: bin/rails "matomo:sync_views[YYYY-MM-DD,YYYY-MM-DD]" (first and last day)'
    end

    Statistics::SyncViews.call(dates: Date.iso8601(args[:from])..Date.iso8601(args[:to]))
  end
end
