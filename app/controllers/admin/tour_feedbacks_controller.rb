# frozen_string_literal: true

class Admin::TourFeedbacksController < Admin::ApplicationController
  def index
    @tour_feedbacks = TourFeedback.all
  end
end
