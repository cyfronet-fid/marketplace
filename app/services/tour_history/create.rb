# frozen_string_literal: true

class TourHistory::Create
  def initialize(tour_history)
    @tour_history = tour_history
  end

  def call
    @tour_history.save

    @tour_history
  end
end
