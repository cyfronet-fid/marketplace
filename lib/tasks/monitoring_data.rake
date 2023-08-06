# frozen_string_literal: true

require "sentry-ruby"

namespace :monitoring_data do
  desc "Monitoring data fetch"

  task fetch: :environment do
    MonitoringData::Fetch.new(
      ENV.fetch("MONITORING_DATA_URL", "https://api.devel.argo.grnet.gr/api"),
      dry_run: ENV.fetch("DRY_RUN", false),
      ids: ENV.fetch("IDS", "").split(","),
      filepath: ENV.fetch("OUTPUT", nil),
      access_token: ENV.fetch("MONITORING_DATA_TOKEN", Rails.application.credentials.monitoring_data[:access_token]),
      start_date: ENV.fetch("MONITORING_DATA_START_DATE", 1.month.ago.beginning_of_month),
      end_date: ENV.fetch("MONITORING_DATA_END_DATE", 1.month.ago.end_of_month)
    ).call
  end
end
