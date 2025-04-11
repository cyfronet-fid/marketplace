# frozen_string_literal: true

class Services::SummariesController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    if prev_visible_step.valid?
      @step = step(session[session_key])
      setup_show_variables!
    else
      redirect_to url_for([@service, prev_visible_step_key]), alert: prev_visible_step.error
    end
  end

  def create
    @step = step(summary_params)
    @bundle_params = session[session_key][:bundled_parameters] || []

    if @step.valid? & verify_recaptcha(model: @step, attribute: :verified_recaptcha)
      do_create(@step.project_item, @bundle_params)
    else
      setup_show_variables!
      render :show, status: :unprocessable_entity, alert: @step.error
    end
  end

  private

  def next_title
    @offer.orderable? ? _("Send access request") : _("Pin!")
  end

  def do_create(project_item_template, bundle_params)
    authorize(project_item_template)

    project_item = ProjectItem::Create.new(project_item_template, message_text, bundle_params: bundle_params).call

    if project_item.persisted?
      session.delete(session_key)
      session.delete(:selected_project)
      send_user_action
      Matomo::SendRequestJob.perform_later(project_item, "AddToProject")
      notice = project_item.orderable? ? "Offer ordered successfully" : "Offer pinned successfully"
      flash[:notice] = notice
      redirect_to project_service_path(project_item.project, project_item)
    else
      flash[:alert] = "Service request configuration is invalid"
      redirect_to url_for([@service, prev_visible_step_key]), alert: "Service request configuration is invalid"
    end
  end

  def step_key
    :summary
  end

  def summary_params
    session[session_key].merge(params.require(:customizable_project_item).permit(:project_id, :additional_comment))
  end

  def setup_show_variables!
    @projects = policy_scope(current_user.projects.active)
    @offer = @step.offer
    @bundle = @step.bundle
    @bundle_params = session[session_key][:bundled_parameters] || []
  end

  def message_text
    params[:customizable_project_item][:additional_comment]
  end

  def project_item_template
    CustomizableProjectItem.new(session[session_key])
  end

  def send_user_action
    return if Mp::Application.config.recommender_host.nil?

    source_id = SecureRandom.uuid

    request_body = {
      timestamp: Time.now.utc.iso8601,
      source: JSON.parse(@recommendation_previous),
      target: {
        page_id: polymorphic_url(@service, routing_type: :path),
        visit_id: source_id
      },
      action: {
        order: true,
        type: "button",
        text: ""
      },
      user_id: current_user.id,
      unique_id: cookies[:client_uid],
      client_id: "marketplace"
    }

    if %w[all recommender_lib].include? Mp::Application.config.user_actions_target
      Probes::ProbesJob.perform_later(request_body.to_json)
    end

    if %w[all jms].include? Mp::Application.config.user_actions_target
      Jms::PublishJob.perform_later(request_body.to_json, :user_actions)
    end
  end
end
