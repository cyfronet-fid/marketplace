# frozen_string_literal: true

class Services::InformationController < Services::ApplicationController
  skip_before_action :authenticate_user!
  before_action :ensure_in_session!

  def show
    if !prev_visible_step_key || prev_visible_step.valid?
      @step = step(@saved_state)
      @offer = @step.offer
      @bundle = @step.bundle

      redirect_to url_for([@service, next_step_key]) unless @step.visible?
    else
      redirect_to url_for([@service, prev_visible_step_key]), alert: prev_visible_step.error
    end
  end

  def update
    if step.valid?
      redirect_to url_for([@service, next_step_key])
    else
      flash[:alert] = @step.error
      render :show
    end
  end

  private

  def step_key
    :information
  end
end
