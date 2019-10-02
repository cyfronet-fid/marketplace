# frozen_string_literal: true

class Services::QuestionsController < ApplicationController
  def new
    @question = Service::Question.new

    respond_to do |format|
      format.html
      format.js { render_modal_form }
    end
  end

  def create
    @service = Service.friendly.find(params[:service_id])
    user = current_user
    @question = Service::Question.new(author: user&.full_name || params[:service_question][:author],
                                     email: user&.email || params[:service_question][:email],
                                     text: params[:service_question][:text],
                                     service: @service)
    respond_to do |format|
      if @question.valid? && verify_recaptcha
        @service.contact_emails.each  do |email|
          ServiceMailer.new_question(email, @question.author, @question.email, @question.text, @service).deliver_later
        end
        format.html { redirect_to service_path(@service) }
        flash[:notice] = "Your message was successfully sent"
      else
        format.html
        format.js { render_modal_form }
      end
    end
  end

  private

    def render_modal_form
      render "services/question_modal",
             content_type: "text/javascript",
             locals: {
                title: "Ask provider",
                action_btn: t("simple_form.labels.question.new"),
                form: "services/questions/form"
             }
    end
end
