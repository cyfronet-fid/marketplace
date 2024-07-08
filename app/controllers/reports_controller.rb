# frozen_string_literal: true

class ReportsController < ApplicationController
  def new
    @report = Report.new
  end

  def create
    user = current_user
    @report =
      Report.new(
        author: user&.full_name || params[:report][:author],
        email: user&.email || params[:report][:email],
        text: params[:report][:text]
      )
    respond_to do |format|
      if @report.valid? & verify_recaptcha(model: @report, attribute: :verified_recaptcha)
        notice = "Your report was successfully sent"
        Report::Create.new(@report).call
        format.turbo_stream { flash.now[:notice] = notice }
        flash[:notice] = notice
      else
        format.json { render :new, status: :unprocessable_entity }
      end
    end
  end
end
