# frozen_string_literal: true

module Tourable
  extend ActiveSupport::Concern

  included { before_action :determine_tour }

  private

  def determine_tour
    tour_name = nil
    if params[:tour].present? && (available_tours.dig(params[:tour], "activation_strategy") == "query_param")
      tour_name = params[:tour]
    end
    if tour_name.nil?
      default_tours =
        available_tours.select do |_, tour|
          tour["activation_strategy"].blank? || tour["activation_strategy"] == "default"
        end

      remaining = default_tours.keys - finished_tours
      to_show = default_tours.select { |_, tour| show_tour?(tour) }.keys
      to_render = (to_show & remaining).first
      tour_name = to_render
    end
    @tour = tour_name.nil? ? {} : { name: tour_name, content: available_tours[tour_name] }
  end

  def available_tours
    # Do we have tours for this controller/action in the user's locale?
    %W[#{controller_name}.#{action_name}.#{I18n.locale} #{controller_name}.#{action_name}.#{I18n.default_locale}]
      .map { |key| Rails.configuration.tours.list[key] }
      .find { |tours| !tours.nil? } || {}
  end

  def finished_tours(controller = controller_name, action = action_name)
    finished = []
    if current_user.present?
      finished |=
        TourHistory.where(user_id: current_user.id, controller_name: controller, action_name: action).map(&:tour_name)
    end

    tour_cookie = cookies["tours-marketplace-#{controller}-#{action}-completed"]
    if tour_cookie.present?
      begin
        finished |= JSON.parse(tour_cookie)
      rescue StandardError
        # Ignored
      end
    end

    finished
  end

  def finished?(tour_name, controller = controller_name, action = action_name)
    finished_tours(controller, action).include?(tour_name)
  end

  def show_tour?(tour)
    if last_part_of_tour?(tour)
      finished?(
        tour.dig("previous", "tour_name"),
        tour.dig("previous", "controller_name"),
        tour.dig("previous", "action_name")
      )
    elsif first_part_of_tour?(tour)
      !finished?(tour.dig("next", "tour_name"), tour.dig("next", "controller_name"), tour.dig("next", "action_name"))
    elsif tour.key?("previous") && tour.key?("next")
      if finished?(tour.dig("next", "tour_name"), tour.dig("next", "controller_name"), tour.dig("next", "action_name"))
        false
      else
        finished?(
          tour.dig("previous", "tour_name"),
          tour.dig("previous", "controller_name"),
          tour.dig("previous", "action_name")
        )
      end
    else
      true
    end
  end

  def last_part_of_tour?(tour)
    tour.key?("previous") && !tour.key?("next")
  end

  def first_part_of_tour?(tour)
    !tour.key?("previous") && tour.key?("next")
  end
end
