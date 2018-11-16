# frozen_string_literal: true

module ServiceHelper
  def print_rating_stars(rating)
    result = ""
    # full stars
    for i in 0...rating.floor
      result += content_tag(:i, "", class: "fas fa-star fa-lg")
    end
    # half stars
    if rating % 1 != 0
      result += content_tag(:i, "", class: "fas fa-star-half-alt fa-lg")
    end
    # empty stars
    for i in 0...5 - rating.ceil
      result += content_tag(:i, "", class: "far fa-star fa-lg")
    end
    result.html_safe
  end

  def get_providers_list
    Provider.all
  end

  def any_present?(record, *fields)
    fields.map { |f| record.send(f) }.any? { |v| v.present? }
  end
end
