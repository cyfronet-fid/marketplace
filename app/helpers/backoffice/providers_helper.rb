# frozen_string_literal: true

module Backoffice::ProvidersHelper
  BASIC_STEPS = %w[profile location contacts managers summary].freeze
  PROVIDER_TABS = %w[profile location contacts managers].freeze
  # pl's provider page tabs (its views come from CUSTOMIZATION_PATH).
  EXTENDED_STEPS = %w[profile classification location contacts maturity dependencies managers other].freeze

  def cant_edit?(attribute)
    !policy([:backoffice, @provider]).permitted_attributes.include?(attribute)
  end

  # pl's views call it without the question mark.
  def cant_edit(attribute)
    cant_edit?(attribute)
  end

  def render_step(step, provider, _legacy_mode = nil)
    render partial_path(step), provider: provider
  end

  def partial_path(step)
    "backoffice/providers/steps/#{step}"
  end

  def next_title
    Mp::Variant.pl? ? "Next" : "Next ->"
  end

  def back_title
    Mp::Variant.pl? ? "Back" : "<- Back"
  end

  def submit_title
    "#{session[:wizard_action].capitalize} provider"
  end

  def save_as_draft_title
    "Save as draft"
  end

  def preloaded(provider)
    params[:provider_id] == "new" ? provider : Provider.with_attached_logo.find(params[:provider_id])
  end

  def basic_steps
    BASIC_STEPS
  end

  def provider_tabs
    PROVIDER_TABS
  end

  def extended_steps
    EXTENDED_STEPS
  end

  def safe_tab(tab)
    extended_steps.include?(tab) ? tab : "profile"
  end

  def safe_step(step)
    basic_steps.include?(step) ? step : basic_steps.first
  end

  def exit_confirm_details
    summary_step = link_to "summary step", "javascript:;", data: { action: "click->form#goToSummary" }
    _("If you leave, you will lose your changes, go to the #{summary_step} and save them")
  end
end
