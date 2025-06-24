# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    @project_item = CustomizableProjectItem.new(session[session_key])
    if prev_visible_step.valid?
      @step = step(saved_state)
      @offer = @step.offer
      @bundle = @step.bundle

      redirect_to url_for([@service, next_step_key]) unless @step.visible?
    else
      redirect_to url_for([@service, prev_visible_step_key]), alert: prev_visible_step.error
    end
  end

  def update
    @step = step(configuration_params)
    @offer = @step.offer || @step.bundle.main_offer
    @bundle = @step.bundle
    @project_item = CustomizableProjectItem.new(configuration_params)

    @step.voucher_id = "" if @step.request_voucher

    if @step.valid?
      save_in_session(@step)
      redirect_to url_for([@service, next_step_key])
    else
      render :show, status: :unprocessable_entity, alert: @step.error
    end
  end

  private

  def configuration_params
    template = CustomizableProjectItem.new(saved_state)
    saved_state.merge(permitted_attributes(template)).merge(status: :created)
  end

  def step_key
    :configuration
  end
end
