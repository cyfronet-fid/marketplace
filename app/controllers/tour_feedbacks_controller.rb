# frozen_string_literal: true

class TourFeedbacksController < ApplicationController
  def create
    tour_params = tour_feedback_params

    @tour_controller_name = tour_params[:tour_controller_name]
    @tour_controller_action = tour_params[:tour_controller_action]
    @tour_name = tour_params[:tour_name]
    @feedback = Rails.configuration.tours.list["#{@tour_controller_name}.#{@tour_controller_action}.#{I18n.locale}"]
    @feedback ||= Rails.configuration.tours.list["#{@tour_controller_name}.#{@tour_controller_action}.#{I18n.default_locale}"]
    return head :not_found unless @feedback

    @feedback = @feedback.dig(@tour_name, "feedback")

    return head :not_found unless @feedback

    @form = params.require(:content).permit(@feedback["questions"].map { |question| question["name"].to_sym })
    @errors = @feedback["questions"].reject do |question|
                @form[question["name"]].blank?
              end.collect { |question| [question["name"], "This field is required"] }.to_h

    if tour_params["share"] && tour_params["email"].blank? && current_user.nil?
      @errors["email"] = "This field is required"
    elsif tour_params["share"] && current_user.nil? && tour_params["email"] !~ /^(.+)@(.+)$/
      @errors["email"] = "Email required"
    elsif tour_params["share"] && current_user.present?
      tour_params["email"] = current_user.email
    elsif !tour_params["share"] && current_user.nil?
      tour_params["email"] = nil
    end

    if @errors.present? || !verify_recaptcha
      @form["share"] = tour_params["share"]
      @form["email"] = tour_params["email"]
      return respond_to do |format|
        format.js do
          render "layouts/show_tour_feedback", status: :bad_request,
                                               locals: {
                                                 feedback_form: "layouts/tours/modal_content",
                                                 feedback_locals: {
                                                   feedback: @feedback,
                                                   errors: @errors,
                                                   form: @form,
                                                   tour_controller_name: @tour_controller_name,
                                                   tour_controller_action: @tour_controller_action,
                                                   tour_name: @tour_name
                                                 }
                                               }
        end
      end
    end

    TourFeedback.new(controller_name: @tour_controller_name,
                     action_name: @tour_controller_action,
                     tour_name: @tour_name,
                     user_id: current_user&.id,
                     email: tour_params["email"],
                     content: @form).save

    head :created
  end

  private

  def tour_feedback_params
    params.permit(:tour_controller_name, :tour_controller_action, :tour_name, :email, :share)
  end
end
