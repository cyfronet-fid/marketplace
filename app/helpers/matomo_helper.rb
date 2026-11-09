# frozen_string_literal: true

# Matomo browser tracking (app/javascript/app/matomo.js, ADR-0008). With
# Matomo off (MP_MATOMO_ENABLED, Matomo::Configuration) the helpers render
# nothing, and the tracker stays idle.
module MatomoHelper
  # Meta tags that configure the tracker; every variant's layouts/_head
  # renders them before the application script.
  def matomo_tags
    return unless matomo_configuration.enabled?

    safe_join(
      [
        tag.meta(name: "matomo-url", content: matomo_configuration.url),
        tag.meta(name: "matomo-site-id", content: matomo_configuration.site_id)
      ],
      "\n"
    )
  end

  # The View event element of a detail page (Matomo::Event.view).
  def matomo_view_event_tag(record)
    matomo_event_tag(Matomo::Event.view(record))
  end

  # The event element contract: a hidden element whose data attributes carry
  # the category, action, name and optional numeric value of a Matomo::Event.
  def matomo_event_tag(event)
    return unless matomo_configuration.enabled?

    tag.div(
      hidden: true,
      data: {
        matomo_event: "",
        matomo_category: event.category,
        matomo_action: event.action,
        matomo_name: event.name,
        matomo_value: event.value
      }
    )
  end

  private

  def matomo_configuration
    Mp::Application.config.matomo
  end
end
