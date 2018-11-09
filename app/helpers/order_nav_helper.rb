# frozen_string_literal: true

module OrderNavHelper
  def order_nav_link(title, path, step, current_step)
    content_tag(:li, class: "nav-item") do
      link_to_if(step <= current_step, title, path,
                 class: "nav-link #{"active" if step == current_step}") do
        if step == current_step + 1
          content_tag(:a, title, class: "nav-link", href: "#",
                      onclick: "document.getElementById('order-form').submit();")
        else
          content_tag(:div, title, class: "nav-link disabled")
        end
      end
    end
  end
end
