# frozen_string_literal: true

class Services::QuestionsController < ApplicationController
  def create
    @service = Service.friendly.find(params[:service_id])
    @service.contact_emails.each  do |email|
      ServiceMailer.new_question(email, params[:service_question], @service).deliver_now
    end

    redirect_to service_path(@service)
    flash[:notice] = "Your message was successfully sended"
  end
end
