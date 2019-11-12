# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    if prev_step.valid?
      @step = step(saved_state)

      unless @step.visible?
        redirect_to service_summary_path(@service)
      end
    else
      redirect_to service_offers_path(@service), alert: prev_step.error
    end
  end

  def update
    @step = step(configuration_params)

    if @step.request_voucher
      @step.voucher_id = ""
    end

    if @step.valid?
      save_in_session(@step)
      redirect_to service_summary_path(@service)
    else
      flash.now[:alert] = @step.error
      render :show
    end
  end

  private
    def configuration_params
      template = ProjectItem.new(saved_state)
      saved_state
        .merge(permitted_attributes(template))
        .merge(status: :created)
    end

    def step(attrs)
      wizard.step(:configuration, attrs)
    end

    def prev_step
      @prev_step ||= wizard.step(:information, saved_state)
    end
end
