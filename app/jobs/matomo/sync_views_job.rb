# frozen_string_literal: true

module Matomo
  # The nightly view sync (ADR-0008 D8, D10). config/schedule.yml runs it on
  # MP_MATOMO_SYNC_CRON while Matomo is on. A failed request to Matomo fails
  # the job, so Sidekiq retries it; re-runs are safe, as the sync only upserts.
  class SyncViewsJob < ApplicationJob
    queue_as :default

    def perform
      # Tracking works without the token, so a Node can collect Views before
      # its reporting user exists.
      if Mp::Application.config.matomo.token_auth.blank?
        Rails.logger.warn("Matomo view sync skipped: MP_MATOMO_TOKEN_AUTH is not set")
        return
      end

      Statistics::SyncViews.call
    end
  end
end
