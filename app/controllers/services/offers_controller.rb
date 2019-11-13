# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  skip_before_action :authenticate_user!

  def index
    init_step_data

    if @service.offers_count == 1
      params[:project_item] = { offer_id: @offers.first.iid }
      update
    end
  end

  def update
    @step = step_class.new(step_params)

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

    def step_class
      ProjectItem::Wizard::OfferSelectionStep
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
      @step = step_class.new(session[session_key])
    end
end
