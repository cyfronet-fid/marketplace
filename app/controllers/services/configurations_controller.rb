# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    setup_show_variables!
    @step = step_class.new(session[session_key])
  end

  def update
    @step = step_class.new(configuration_params)

    if @step.request_voucher
      @step.voucher_id = ""
    end

    if @step.valid?
      save_in_session(@step)
      redirect_to service_summary_path(@service)
    else
      setup_show_variables!
      render :show
    end
  end

  private
    def configuration_params
      template = ProjectItem.new(session[session_key])
      session[session_key].
          merge(permitted_attributes(template)).
          merge(status: :created)
    end

    def setup_show_variables!
      @projects = policy_scope(current_user.projects.active)
    end

    def step_class
      ProjectItem::Wizard::ConfigurationStep
    end
end
