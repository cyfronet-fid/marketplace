# frozen_string_literal: true

module ComparisonsHelper
  def checked?(slug)
    session[:comparison]&.include?(slug)
  end

  def options(slug, comparison_enabled)
    if !checked?(slug) && comparison_enabled
      {
        "data-toggle": "tooltip",
        "data-trigger": "hover",
        tabindex: "0",
        title: "You have reached the maximum number of items you can compare"
      }
    else
      {}
    end
  end

  def row_class(idx)
    idx.even? ? nil : "lightgrey-row"
  end
end
