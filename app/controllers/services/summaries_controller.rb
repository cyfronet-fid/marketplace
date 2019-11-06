# frozen_string_literal: true

class Services::SummariesController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    if ProjectItem::Wizard::ConfigurationStep.new(session[session_key]).valid?
      @step = step_class.new(session[session_key])
      @offer_type = @step&.offer&.offer_type
    else
      redirect_to service_configuration_path(@service),
                  alert: "Please configure your service request"
    end
  end

  def create
    @step = step_class.new(summary_params)

    if @step.valid?
      do_create(@step.project_item)
    else
      @service.normal? ? (render "show_normal") : (render "show_open_access")
    end
  end

  private

    def do_create(project_item_template)
      authorize(project_item_template)

      @project_item = ProjectItem::Create.new(project_item_template).call

      if @project_item.persisted?
        session.delete(session_key)
        session.delete(:selected_project)
        redirect_to project_service_path(@project_item.project, @project_item),
                    notice: "Service ordered sucessfully"
      else
        redirect_to service_configuration_path(@service),
                    alert: "Service request configuration invalid"
      end
    end

    def step_class
      ProjectItem::Wizard::ConfigurationStep
    end

    def summary_params
      session[session_key]
    end
end
