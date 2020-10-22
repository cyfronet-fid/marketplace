# frozen_string_literal: true

module TourHelper
  def tour(show_popup)
    # Do we have tours for this controller/action in the user's locale?
    tours = Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.locale}"]
    tours ||= Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.default_locale}"]
    tours ||= {}

    if !tours.empty? || show_popup
      remaining = tours.keys - finished_tours
      to_show = tours.select { |t| show_tour?(t, tours[t]) }.keys
      to_render = to_show & remaining
      render(partial: "layouts/tour",
             locals: { tour_name: to_render.first,
                      show_popup: show_popup,
                      steps: (!tours.empty? && tours[to_render.first]) ? tours[to_render.first]["steps"] : [],
                      next_tour: further_tour(tours[to_render.first] || {}) })
    end
  end

  def finished_tours(controller = controller_name, action = action_name)
    user_cookie(controller, action) ? JSON.parse(user_cookie(controller, action)) : []
  end

  def finished?(tour_name, controller = controller_name, action = action_name)
    user_cookie(controller, action) ? JSON.parse(user_cookie(controller, action)).include?(tour_name) : false
  end

  def show_tour?(tour_name, tour)
    if last_part_of_tour?(tour)
      finished?(tour.dig("previous", "tour_name"),
                tour.dig("previous", "controller_name"),
                tour.dig("previous", "action_name"))
    elsif first_part_of_tour?(tour)
      !finished?(tour.dig("next", "tour_name"),
                 tour.dig("next", "controller_name"),
                 tour.dig("next", "action_name"))
    elsif tour.key?("previous") && tour.key?("next")
      if finished?(tour.dig("next", "tour_name"),
                   tour.dig("next", "controller_name"),
                   tour.dig("next", "action_name"))
        false
      else
        finished?(tour.dig("previous", "tour_name"),
                  tour.dig("previous", "controller_name"),
                  tour.dig("previous", "action_name"))
      end
    else
      true
    end
  end

  def user_cookie(controller = controller_name, action = action_name)
    cookies["#{cookie_prefix(controller, action)}-completed"]
  end

  def further_tour(tour)
    tour.dig("next")
  end

  def next_tour_link(next_tour_path, controller_params_map)
    params = controller_params_map.map { |param_id, mapped_Id| [mapped_Id.to_sym, self.controller.params[param_id]] }.to_h
    puts(params)
    next_tour_path.blank? ? nil : send(next_tour_path, params).to_s
  end

  def cookie_prefix(controller = controller_name, action = action_name)
    "tours-marketplace-#{controller}-#{action}"
  end

  def last_part_of_tour?(tour)
    tour.key?("previous") && !tour.key?("next")
  end

  def first_part_of_tour?(tour)
    !tour.key?("previous") && tour.key?("next")
  end

  def tours_domain
    request.host
  end
end
