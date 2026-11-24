# frozen_string_literal: true

module Matomo
  # The nightly view sync (ADR-0008 D8, D10, D11). config/schedule.yml runs it on
  # MP_MATOMO_SYNC_CRON while Matomo is on. A failed request to Matomo fails
  # the job, so Sidekiq retries it; re-runs are safe, as the sync only upserts.
  class SyncViewsJob < ApplicationJob
    queue_as :default

    # enqueued_at is the time sidekiq-cron enqueued the run (date_as_argument
    # in config/schedule.yml). A retry keeps it, so a retry on a later day
    # still reads the days of its run. A run without it reads up to today.
    def perform(enqueued_at = Time.current.to_f)
      # There is no cron entry while Matomo is off, but a retry from before or
      # a manual run can still start the job.
      return unless Mp::Application.config.matomo.enabled?

      # Tracking works without the token, so a Node can collect Views before
      # its reporting user exists.
      if Mp::Application.config.matomo.token_auth.blank?
        Rails.logger.warn("Matomo view sync skipped: MP_MATOMO_TOKEN_AUTH is not set")
        return
      end

      # The day of the run and the two before.
      last_day = Time.zone.at(enqueued_at).to_date
      Statistics::SyncViews.call(dates: (last_day - 2)..last_day)
    end
  end
end
