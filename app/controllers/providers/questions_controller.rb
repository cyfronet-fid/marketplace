# frozen_string_literal: true

class Providers::QuestionsController < ApplicationController
  def new
    @question = Provider::Question.new
    @provider = Provider.friendly.find(params[:provider_id])

    respond_to do |format|
      format.js { render_modal_form }
    end
  end

  def create
    @provider = Provider.friendly.find(params[:provider_id])
    user = current_user
    @question = Provider::Question.new(author: user&.full_name || params[:provider_question][:author],
                                       email: user&.email || params[:provider_question][:email],
                                       text: params[:provider_question][:text],
                                       provider: @provider)
    respond_to do |format|
      if @question.valid? && verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        @provider.public_contacts.each do |contact|
          ProviderMailer.new_question(contact.email, @question.author, @question.email,
                                      @question.text, @provider).deliver_later
        end
        format.html { redirect_to provider_path(@provider) }
        flash[:notice] = "Your message was successfully sent"
      else
        format.js { render_modal_form }
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
             form_locals: { provider: @provider, question: @question }
           }
  end
end
