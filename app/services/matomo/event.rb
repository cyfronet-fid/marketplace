# frozen_string_literal: true

module Matomo
  # One Matomo event that the browser tracker (app/javascript/app/matomo.js)
  # sends after the page view. Pages render it as an event element
  # (MatomoHelper#matomo_event_tag).
  Event = Data.define(:category, :action, :name, :value) do
    # The View event of a Service (Datasource too), Provider or Bundle detail
    # page (ADR-0008 D6). Names are PIDs, which are stable across slug
    # changes; a bundle has none, so its name is "<service PID>:<bundle iid>".
    def self.view(record)
      case record
      when Bundle then new(category: "Bundle", action: "View", name: "#{record.service.pid}:#{record.iid}")
      when Provider then new(category: "Provider", action: "View", name: record.pid)
      when Service then new(category: "Service", action: "View", name: record.pid)
      else raise ArgumentError, "no View event for #{record.class}"
      end
    end

    def initialize(category:, action:, name:, value: nil)
      super
    end
  end
end
