# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authenticate_service!

  layout "order"

  attr_reader :wizard
  helper_method :step_for
  helper_method :step_key
  helper_method :next_step_key
  helper_method :prev_step_key

  private

    def session_key
      @service.id.to_s
    end

    def ensure_in_session!
      unless saved_state
        redirect_to service_offers_path(@service),
                    alert: "Service request template not found"
      end
    end

    def load_and_authenticate_service!
      @service = Service.friendly.find(params[:service_id])
      authorize(@service, :order?)
      @wizard = ProjectItem::Wizard.new(@service)
    end

    def save_in_session(step)
      session[session_key] = step.project_item.attributes
    end

    def saved_state
      session[session_key]
    end

    def step(attrs = saved_state)
      wizard.step(step_key, attrs)
    end

    def step_for(step_key, attrs = saved_state)
      wizard.step(step_key, attrs)
    end

    def next_step_key
      wizard.next_step_key(step_key)
    end

    def prev_step_key
      wizard.prev_step_key(step_key)
    end

    def prev_step
      wizard.step(wizard.prev_step_key(step_key), saved_state)
    end

    def step_key
      raise "Should be implemented in descendent class"
    end
end
