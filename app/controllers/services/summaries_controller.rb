# frozen_string_literal: true

class Services::SummariesController < Services::ApplicationController
  before_action :ensure_in_session!

  def show
    if prev_visible_step.valid?
      @step = step(session[session_key])
      setup_show_variables!
    else
      redirect_to url_for([@service, prev_visible_step_key]), alert: prev_visible_step.error
    end
  end

  def create
    @step = step(summary_params)

    if @step.valid? & verify_recaptcha(model: @step, attribute: :verified_recaptcha)
      do_create(@step.project_item)
    else
      setup_show_variables!
      flash.now[:alert] = @step.error
      render "show"
    end
  end

  private
    def next_title
      I18n.t("services.summary.#{helpers.map_view_to_order_type(@offer)}.order.title")
    end

    def do_create(project_item_template)
      authorize(project_item_template)

      @project_item = ProjectItem::Create.new(project_item_template, message_text).call

      if @project_item.persisted?
        session.delete(session_key)
        session.delete(:selected_project)
        Matomo::SendRequestJob.perform_later(@project_item, "AddToProject")
        redirect_to project_service_path(@project_item.project, @project_item),
                                  notice: "Service ordered successfully"
      else
        redirect_to url_for([@service, prev_visible_step_key]),
                    alert: "Service request configuration is invalid"
      end
    end

    def step_key
      :summary
    end

    def summary_params
      session[session_key].merge(params.require(:project_item).permit(:project_id))
    end

    def setup_show_variables!
      @projects = policy_scope(current_user.projects.active)
      @offer = @step.offer
    end

    def message_text
      params[:project_item][:additional_comment]
    end
end
