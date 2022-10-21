# frozen_string_literal: true

module Sentryable
  extend ActiveSupport::Concern

  included { before_action :set_sentry_context, if: :sentry_enabled? }

  private

  def set_sentry_context
    Sentry.set_user(id: current_user.id, uid: current_user.uid) if current_user
  end

  def sentry_enabled?
    Rails.env.production? && ENV.fetch("SENTRY_DSN", nil)
  end
end
