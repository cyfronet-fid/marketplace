# frozen_string_literal: true

# Meta tags that configure the browser Sentry SDK
# (app/javascript/app/sentry.js). The helper gives no tags when SENTRY_DSN
# is not set, the same switch as config/initializers/sentry.rb.
module SentryHelper
  def sentry_browser_tags
    dsn = ENV.fetch("SENTRY_DSN", nil)
    return if dsn.blank?

    tags = [
      tag.meta(name: "sentry-dsn", content: dsn),
      tag.meta(name: "sentry-environment", content: ENV["SENTRY_ENVIRONMENT"] || Rails.env)
    ]
    # The same release as config.release of the server, thus the UI can
    # filter the browser events and the server events of one deploy together.
    release = ENV.fetch("MP_VERSION", "").split.last
    tags << tag.meta(name: "sentry-release", content: release) if release.present?
    if current_user
      tags << tag.meta(name: "sentry-user-id", content: current_user.id)
      tags << tag.meta(name: "sentry-user-uid", content: current_user.uid)
    end
    safe_join(tags, "\n")
  end
end
