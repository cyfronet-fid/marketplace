# frozen_string_literal: true

class Services::QuestionsController < ApplicationController
  def new
    @question = Service::Question.new
    @service = Service.friendly.find(params[:service_id])
    # authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
  end

  def create
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
    user = current_user
    @question =
      Service::Question.new(
        author: user&.full_name || params[:service_question][:author],
        email: user&.email || params[:service_question][:email],
        text: params[:service_question][:text],
        service: @service
      )
    respond_to do |format|
      if @question.valid? && verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        Service::Question::Deliver.new(@question).call
        flash[:notice] = "Question was successfully created"
        format.html { redirect_to provider_path(@provider) }
        format.turbo_stream { flash[:notice] = "Question was successfully created" }
      else
        verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        format.html { render :new, question: @question, status: :unprocessable_entity }
        format.json { render :new, question: @question, status: :unprocessable_entity }
      end
    end
  end

  private

  def render_modal_form
    render "layouts/show_modal",
           content_type: "text/javascript",
           locals: {
             title: "Ask provider",
             action_btn: t("simple_form.labels.question.new"),
             form: "services/questions/form",
             form_locals: {
               service: @service,
               question: @question
             }
           }
  end
end
