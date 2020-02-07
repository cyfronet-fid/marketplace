# frozen_string_literal: true

class ReportsController < ApplicationController
  def new
    @report = Report.new

    respond_to do |format|
      format.js { render_modal_form }
    end
  end

  def create
    user = current_user
    @report = Report.new(author: user&.full_name || params[:report][:author],
                              email: user&.email || params[:report][:email],
                              text: params[:report][:text])
    respond_to do |format|
      if @report.valid? && verify_recaptcha
        Report::Create.new(@report).call
        format.js { render js: "window.top.location.reload(true);" }
        flash[:notice] = "Your report was successfully sent"
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
                 title: "Report a technical issue",
                 action_btn: t("simple_form.labels.question.new"),
                 form: "reports/form",
                 form_locals: { report: @report }
             }
    end
end
