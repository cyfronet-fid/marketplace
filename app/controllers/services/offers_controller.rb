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
      redirect_to service_information_path(@service)
    else
      init_step_data
      flash.now[:alert] = @step.error
      render :index
    end
  end

  private

    def step(attrs = nil)
      wizard.step(:offers, attrs)
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
      @offers = @service.offers.reject { |o| o.draft? }
      @step = step(session[session_key])
    end
end
