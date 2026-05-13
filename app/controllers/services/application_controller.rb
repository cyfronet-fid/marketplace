# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :check_vo_membership!
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
    @service.is_a?(DeployableService) ? "ds_#{@service.id}" : @service.id.to_s
  end

  def ensure_in_session!
    choose_offer_path =
      if @service.is_a?(DeployableService)
        deployable_service_choose_offer_path(@service)
      else
        service_choose_offer_path(@service)
      end
    redirect_to choose_offer_path, alert: "Service request template not found" unless @saved_state
  end

  def check_vo_membership!
    token = session["token"]

    unless token.present?
      Rails.logger.warn("Missing check-in token in session")
      redirect_to destroy_user_session_path, alert: "Your session has expired. Please sign in again."
      return
    end

    client_options = Devise.omniauth_configs[:checkin].strategy.client_options
    client_id = client_options[:identifier]
    client_secret = client_options[:secret]

    url = client_options[:introspection_uri]
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(url)
    request.basic_auth(client_id, client_secret)

    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.set_form_data(token: token)

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("Token introspection failed: #{response.code}")

      redirect_to root_path, alert: "Authentication verification failed"
      return
    end

    begin
      body = JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error("Invalid introspection response: #{e.message}")

      redirect_to root_path, alert: "Authentication verification failed"
      return
    end

    entitlements = Array(body["entitlements"])

    vo_group_name = Rails.application.config.vo_group_name
    has_vo_membership = entitlements.any? { |entitlement| entitlement.include?(vo_group_name) }

    unless has_vo_membership
      get_vo_membership_url = Devise.omniauth_configs[:checkin].options[:become_vo_member_url]

      if get_vo_membership_url.present?
        redirect_to get_vo_membership_url, allow_other_host: true
      else
        Rails.logger.error("Missing become_vo_member_url")
        redirect_to root_path, alert: "VO membership URL is not configured"
      end
    end
  end

  def load_and_authenticate_service!
    @service = find_service_or_deployable_service
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :order?)
    @wizard = ProjectItem::Wizard.new(@service)
  end

  def find_service_or_deployable_service
    if params[:deployable_service_id].present?
      DeployableService.friendly.find(params[:deployable_service_id])
    else
      Service.friendly.find(params[:service_id])
    end
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
