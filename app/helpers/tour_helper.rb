# frozen_string_literal: true

module TourHelper
  def tour
    # Do we have tours for this controller/action in the user's locale?
    tours = Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.locale}"]
    tours ||= Rails.configuration.tours.list["#{controller_name}.#{action_name}.#{I18n.default_locale}"]

    if tours
      remaining = tours.keys - finished_tours.map(&:tour_name)

      if remaining.any? && !cookies["#{cookie_prefix("unlogged")}-#{remaining.first}"]
        render(partial: "layouts/tour",
        locals: { tour_name: remaining.first,
        steps: tours[remaining.first]["steps"] })
      end
    end
  end

  def finished_tours
    TourHistory.where(
      user_id: current_user&.id,
      action_name: action_name,
      controller_name: controller_name
    )
  end

  def finished?
    TourHistory.where(
      user_id: current_user.id,
      controller_name: controller_name,
      action_name: action_name
    ).empty?
  end

  def cookie_prefix(user_id = current_user ? current_user.id : "unlogged")
    "tours-mp-#{user_id}-#{controller_name}-#{action_name}"
  end

  def tours_domain
    request.host
  end
end
