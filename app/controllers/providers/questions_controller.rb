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
      if @question.valid? & verify_recaptcha(model: @question, attribute: :verified_recaptcha)
        Provider::Question::Deliver.new(@question).call
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
