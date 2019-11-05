# frozen_string_literal: true

class Services::OffersController < Services::ApplicationController
  skip_before_action :authenticate_user!

  def index
    init_step_data

    if @service.offers_count == 1
      params[:project_item] = { offer_id: @offers.first.id }
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

    def save_in_session(step)
      session[session_key] = step.project_item.attributes
    end

    def step_class
      ProjectItem::Wizard::OfferSelectionStep
    end

    def step_params
      params.fetch(:project_item, session[session_key] || {})
        .permit(:offer_id)
        .merge(project_id: session[:selected_project])
    end

    def init_step_data
      @offers = @service.offers.reject { |o| o.draft? }
      @step = step_class.new(session[session_key])
    end
end
