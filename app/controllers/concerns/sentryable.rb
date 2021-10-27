# frozen_string_literal: true

module Sentryable
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_context, if: :sentry_enabled?
  end

  private

  def set_sentry_context
    Sentry.set_user(id: current_user.id, uid: current_user.uid) if current_user
  end

  def sentry_enabled?
    Rails.env.production? && ENV["SENTRY_DSN"]
  end
end
