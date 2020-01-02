# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  skip_before_action :authenticate_user!

  def show
    init_step_data

    unless step.visible?
      params[:project_item] = { offer_id: @offers.first.iid }
      update
    end
  end

  def update
    @step = step(step_params)

    if @step.valid?
      save_in_session(@step)
      redirect_to [@service, next_step_key]
    else
      init_step_data
      flash.now[:alert] = @step.error
      render :show
    end
  end

  private
    def step_key
      :offers
    end

    def step_params
      { offer_id: offer&.id, project_id: session[:selected_project] }
    end

    def offer
      form_params = params
        .fetch(:project_item, session[session_key] || {})
        .permit(:offer_id)
      @service.offers.find_by(iid: form_params[:offer_id])
    end

    def init_step_data
      @offers = policy_scope(@service.offers).order(:created_at)
      @step = step(session[session_key])
    end
end
