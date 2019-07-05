# frozen_string_literal: true

class Services::ConfigurationsController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    setup_show_variables!
    @project_item = ProjectItem.new(session[session_key])
    render "show_#{@service.service_type}"
  end

  def update
    @project_item = ProjectItem.new(configuration_params)

    if @project_item.request_voucher
      @project_item.voucher_id = ""
    end

    if @project_item.valid?
      session[session_key] = @project_item.attributes
      redirect_to service_summary_path(@service)
    else
      setup_show_variables!
      render "show_#{@service.service_type}"
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
      @projects = current_user.projects
    end
end
