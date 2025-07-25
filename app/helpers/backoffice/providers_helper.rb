# frozen_string_literal: true

module Backoffice::ProvidersHelper
  BASIC_STEPS = %w[profile location contacts managers summary].freeze
  EXTENDED_STEPS = %w[profile classification location contacts maturity dependencies managers other].freeze

  def cant_edit(attribute)
    !policy([:backoffice, @provider]).permitted_attributes.include?(attribute)
  end

  def render_step(step, provider, extended_form)
    render partial_path(step, extended_form: extended_form), provider: provider, extended_form: extended_form
  end

  def form_directory(extended_form)
    extended_form ? "form" : "steps"
  end

  def partial_path(step, extended_form: false)
    "backoffice/providers/#{form_directory(extended_form)}/#{step}"
  end

  def next_title
    "Next ->"
  end

  def back_title
    "<- Back"
  end

  def submit_title
    "#{session[:wizard_action].capitalize} provider"
  end

  def preloaded(provider)
    params[:provider_id] == "new" ? provider : Provider.with_attached_logo.find(params[:provider_id])
  end

  def basic_steps
    BASIC_STEPS
  end

  def extended_steps
    EXTENDED_STEPS
  end

  def exit_confirm_details
    summary_step = link_to "summary step", "javascript:;", data: { action: "click->form#goToSummary" }
    _("If you leave, you will lose your changes, go to the #{summary_step} and save them")
  end
end
