# frozen_string_literal: true

module Sentryable
  extend ActiveSupport::Concern

  included do
    before_action :set_raven_context, if: :sentry_enabled?
  end

  private
    def set_raven_context
      if current_user
        Raven.user_context(id: current_user.id,
                          email: current_user.email,
                          username: current_user.full_name)
      end
      Raven.extra_context(params: params.permit!.to_h, url: request.url)
    end

    def sentry_enabled?
      Rails.env.production?
    end
end
