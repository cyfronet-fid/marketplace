# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    setup_show_variables!
    @project_item = CustomizableProjectItem.new(session[session_key])
    if prev_visible_step.valid?
      @step = step(saved_state)

      unless @step.visible?
        redirect_to url_for([@service, next_step_key])
      end
    else
      redirect_to url_for([@service, pref_visible_step_key]), alert: prev_visible_step.error
    end
  end

  def update
    @step = step(configuration_params)
    @project_item = CustomizableProjectItem.new(configuration_params)

    @bundled_parameters = @project_item.properties["bundled_services"]&.map { |o| [o["offer_id"], o["attributes"]] }.to_h

    if @step.request_voucher
      @step.voucher_id = ""
    end

    if @step.valid?
      save_in_session(@step)
      session[:bundle] = @bundled_parameters
      redirect_to url_for([@service, next_step_key])
    else
      flash.now[:alert] = @step.error
      render :show
    end
  end

  private
    def configuration_params
      template = CustomizableProjectItem.new(saved_state)
      saved_state
          .merge(permitted_attributes(template))
          .merge(status: :created)
    end

    def step_key
      :configuration
    end

    def setup_show_variables!
      @projects = current_user.projects
      # @affiliations = current_user.active_affiliations
      # @customer_topologies = ProjectItem.customer_typologies.keys.map(&:to_sym)
    end
end
