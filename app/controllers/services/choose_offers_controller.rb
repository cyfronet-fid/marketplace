# frozen_string_literal: true

class Services::ChooseOffersController < Services::ApplicationController
  prepend_before_action :check_vo_membership!, only: :show

  def show
    pi_init = params[:customizable_project_item]
    if pi_init && (pi_init[:offer_id] || pi_init[:bundle_id])
      update
      return # Prevent further processing after update call
    end

    # Check if step should be auto-selected before initializing step data
    temp_step = step({}) # Create step without full initialization to check visibility
    unless temp_step.visible?
      init_step_data # Only init data for auto-selection
      if @offers.inclusive.size.positive?
        params[:customizable_project_item] = { offer_id: @offers.inclusive.first.iid }
      elsif @bundles.published.size.positive?
        params[:customizable_project_item] = { bundle_id: @bundles.published.first.iid }
      end
      update
      return # Prevent further processing after update
    end

    init_step_data # Normal flow - init data for visible step
  end

  def update
    @step = step(step_params)

    if @step.valid?
      save_in_session(@step)
      redirect_to url_for([@service, next_step_key])
    else
      init_step_data
      # Don't show validation error if step should be invisible (auto-selection case)
      flash[:alert] = @step.error if @step.visible?
      render :show
    end
  end

  private

  def check_vo_membership!
    return unless user_signed_in?

    result = Checkin::CheckVoMembership.call(
      access_token: session["token"],
      refresh_token: session["refresh_token"]
    )

    session["refresh_token"] = result.refresh_token if result.refresh_token.present?
    session["token"] = result.access_token if result.access_token.present?

    case result.status
    when :misconfiguration
      redirect_to root_path, alert: _("We can't verify your VO membership. Please contact admin.")
    when :session_expired
      sign_out(current_user)
      redirect_to root_path, alert: _("Your session has expired. Please sign in again.")
    when :verification_failed
      redirect_to root_path, alert: _("Your VO membership verification has failed.")
    when :not_member
      redirect_to result.become_vo_member_url, allow_other_host: true
    end
  end

  def step_key
    :choose_offer
  end

  def step_params
    { offer_id: offer&.id, bundle_id: bundle&.id, project_id: session[:selected_project] }
  end

  def offer
    form_params = params.fetch(:customizable_project_item, session[session_key] || {}).permit(:offer_id)
    @service.offers.find_by(iid: form_params[:offer_id] || bundle&.main_offer&.iid)
  end

  def bundle
    form_params = params.fetch(:customizable_project_item, session[session_key] || {}).permit(:bundle_id)
    @service.bundles.find_by(iid: form_params[:bundle_id])
  end

  def init_step_data
    @offers = policy_scope(@service.offers.active).order(:iid)
    @bundles = policy_scope(@service.bundles.published).order(:iid)
    @bundled = policy_scope(@service.offers.published).order(:iid).select(&:bundled?).map(&:bundles)&.flatten
    @step = step(session[session_key])
  end
end
