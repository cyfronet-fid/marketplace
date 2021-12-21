# frozen_string_literal: true

class TourHistoriesController < ApplicationController
  def create
    @tours_history = TourHistory.new(tour_history_params)
    @tours_history.user_id = current_user.id
    respond_to do |format|
      if @tours_history.save
        format.json { render json: @tours_history, status: :created }
      else
        format.json { render json: @tours_history.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def tour_history_params
    params.require(:tour_history).permit(:controller_name, :action_name, :tour_name)
  end
end
