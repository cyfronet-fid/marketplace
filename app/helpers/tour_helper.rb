# frozen_string_literal: true

module TourHelper
  def tour
    # Do we have tours for this controller/action in the user's locale?
    tours = Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.locale}"]
    tours ||= Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.default_locale}"]

    if tours
      remaining = tours.keys - finished_tours
      to_show = tours.select { |t| show_tour?(t, tours[t]) }.keys
      to_render = to_show & remaining
      unless to_render.empty?
        render(partial: "layouts/tour",
               locals: { tour_name: to_render.first,
               steps: tours[to_render.first]["steps"],
               next_tour: further_tour(tours[to_render.first]) })
      end
    end
  end

  def finished_tours(controller = controller_name, action = action_name)
    user_cookie(controller, action) ? JSON.parse(user_cookie(controller, action)) : []
  end

  def finished?(tour_name, controller =  controller_name, action =  action_name)
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
    tour.dig("next", "redirect_to")
  end

  def next_tour_link(next_tour_path)
    next_tour_path.blank? ? nil : send(next_tour_path).to_s
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
