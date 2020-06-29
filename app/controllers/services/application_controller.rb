# frozen_string_literal: true

class Services::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :load_and_authenticate_service!

  layout "order"

  attr_reader :wizard
  helper_method :wizard_title
  helper_method :step_for
  helper_method :step_key, :prev_visible_step_key
  helper_method :step_title, :prev_title, :next_title

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

    def next_visible_step_key
      @next_visible_step_key ||= find_next_visible_step_key(step_key)
    end

    def find_next_visible_step_key(step_key)
      next_step_key = wizard.next_step_key(step_key)

      if next_step_key == nil || step_for(next_step_key).visible?
        next_step_key
      else
        find_next_visible_step_key(next_step_key)
      end
    end

    def prev_visible_step_key
      @prev_visible_step_key ||= find_prev_visible_step_key(step_key)
    end

    def find_prev_visible_step_key(step_key)
      prev_step_key = wizard.prev_step_key(step_key)

      if prev_step_key == nil || step_for(prev_step_key).visible?
        prev_step_key
      else
        find_prev_visible_step_key(prev_step_key)
      end
    end

    def prev_step_key
      wizard.prev_step_key(step_key)
    end

    def prev_visible_step
      wizard.step(prev_visible_step_key, saved_state)
    end

    def step_key
      raise "Should be implemented in descendent class"
    end

    def step_title(step_name = step_key)
      I18n.t("services.#{step_name}.title")
    end

    def next_title
      if next_visible_step_key == wizard.step_names.last
        "#{I18n.t("services.order.wizard.next", step_title: step_title(next_visible_step_key))}"
      else
        I18n.t("next")
      end
    end

    def prev_title
      "#{I18n.t("services.order.wizard.previous", step_title: step_title(prev_visible_step_key))}"
    end

    def wizard_title
      if step.offer
        "#{@service.name} - #{step.offer.name}"
      else
        @service.name
      end
    end
end
