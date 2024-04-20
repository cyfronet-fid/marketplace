# frozen_string_literal: true

class Providers::QuestionsController < ApplicationController
  before_action :ensure_frame_response, only: %i[new edit]
  def new
    @question = Provider::Question.new
    @provider = Provider.friendly.find(params[:provider_id])
  end

  def create
    @provider = Provider.friendly.find(params[:provider_id])
    user = current_user
    @question =
      Provider::Question.new(
        author: user&.full_name || params[:provider_question][:author],
        email: user&.email || params[:provider_question][:email],
        text: params[:provider_question][:text],
        provider: @provider
      )
    respond_to do |format|
      if @question.valid? && verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        Provider::Question::Deliver.new(@question).call
        flash.now[:notice] = "Question was successfully created"
        format.html { redirect_to provider_path(@provider) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "layouts/flash") }
      else
        verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render :new, status: :unprocessable_entity }
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
             form: "providers/questions/form",
             form_locals: {
               provider: @provider,
               question: @question
             }
           }
  end
end
