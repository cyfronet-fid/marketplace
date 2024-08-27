# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authenticate_service!
  before_action :saved_state

  layout "order"

  attr_reader :wizard
  helper_method :wizard_title
  helper_method :step_for
  helper_method :step_key, :prev_visible_step_key
  helper_method :step_title, :prev_title, :next_title

  STEP_TITLES = {
    choose_offer: "Offer selection",
    information: "Access instructions",
    configuration: "Configuration",
    summary: "Final details"
  }.freeze

  private

  def session_key
    @service.id.to_s
  end

  def ensure_in_session!
    redirect_to service_choose_offer_path(@service), alert: "Service request template not found" unless @saved_state
  end

  def load_and_authenticate_service!
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :order?)
    @wizard = ProjectItem::Wizard.new(@service)
  end

  def save_in_session(step)
    session[session_key] = step.project_item.attributes
    session[session_key][:bundled_parameters] = step.project_item.bundled_parameters.transform_keys(&:id) if step
      .project_item
      .bundled_parameters
      .present?
  end

  def saved_state
    @saved_state = session[session_key]
  end

  def step(attrs = @saved_state)
    wizard.step(step_key, attrs)
  end

  def step_for(step_key, attrs = @saved_state)
    wizard.step(step_key, attrs)
  end

  def next_step_key
    wizard.next_step_key(step_key)
  end

  def next_visible_step_key
    @next_visible_step_key ||= find_next_visible_step_key(step_key)
  end

  def find_next_visible_step_key(step_key)
    next_step_key = wizard.next_step_key(step_key)

    next_step_key.nil? || step_for(next_step_key).visible? ? next_step_key : find_next_visible_step_key(next_step_key)
  end

  def prev_visible_step_key
    @prev_visible_step_key ||= find_prev_visible_step_key(step_key)
  end

  def find_prev_visible_step_key(step_key)
    prev_step_key = wizard.prev_step_key(step_key)

    prev_step_key.nil? || step_for(prev_step_key).visible? ? prev_step_key : find_prev_visible_step_key(prev_step_key)
  end

  def prev_step_key
    wizard.prev_step_key(step_key)
  end

  def prev_visible_step
    wizard.step(prev_visible_step_key, @saved_state)
  end

  def step_key
    raise "Should be implemented in descendent class"
  end

  def step_title(step_name = step_key)
    step_name == :summary && !@step.offer&.orderable? ? "Pin to a project" : STEP_TITLES[step_name]
  end

  def next_title
    _("Next")
  end

  def prev_title
    _("Back to previous step - %{step_title}") % { step_title: step_title(prev_visible_step_key) }
  end

  def wizard_title
    if step.offer && (@service.offers_count > 1)
      "#{@service.name} - #{step.offer.name}"
    elsif step.bundle.present?
      "#{@service.name} - #{step.bundle.name}"
    else
      @service.name
    end
  end
end
