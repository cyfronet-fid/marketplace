# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""
    # full stars
    for i in 0...rating.floor
      result += content_tag(:i, "", class: "fas fa-star")
    end
    # half stars
    if rating % 1 != 0
      result += content_tag(:i, "", class: "fas fa-star-half-alt")
    end
    # empty stars
    for i in 0...5 - rating.ceil
      result += content_tag(:i, "", class: "far fa-star")
    end
    result.html_safe
  end

  def order_button_text
    @service.open_access ? "Add to my services" : "Order"
  end

  def get_providers_list
    Provider.all
  end
end
