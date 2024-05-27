# frozen_string_literal: true

class Services::QuestionsController < ApplicationController
  def new
    @question = Service::Question.new
    @service = Service.friendly.find(params[:service_id])
    authorize(ServiceContext.new(@service, params.key?(:from) && params[:from] == "backoffice_service"), :show?)
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
      if @question.valid? & verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        Service::Question::Deliver.new(@question).call
        notice = "Your message was successfully sent"
        format.html { redirect_to provider_path(@provider, notice: notice) }
        format.turbo_stream { flash.now[:notice] = notice }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render :new, status: :unprocessable_entity }
      end
    end
  end
end
