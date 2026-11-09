# frozen_string_literal: true

module Matomo
  # Matomo events of an action that ends in a redirect (ADR-0008 D7): the
  # controller adds them to the flash, and the page the redirect lands on
  # renders them as event elements (MatomoHelper#matomo_pending_event_tags), so
  # the browser sends them in the same visit as the page views before.
  #
  # Events are kept as plain arrays under one flash key, which the session
  # serializer stores as they are.
  class PendingEvents
    include Enumerable

    KEY = "matomo_events"

    def initialize(flash)
      @flash = flash
    end

    # Does nothing with Matomo off (MP_MATOMO_ENABLED, Matomo::Configuration),
    # or without a name: events are named by PID, and a deployable service may
    # have none.
    def add(category:, action:, name:, value: nil)
      return if name.blank? || !Mp::Application.config.matomo.enabled?

      @flash[KEY] = [*stored, Event.new(category:, action:, name:, value:).deconstruct]
    end

    def each(&)
      stored.map { |values| Event.new(*values) }.each(&)
    end

    private

    def stored
      @flash[KEY] || []
    end
  end
end
