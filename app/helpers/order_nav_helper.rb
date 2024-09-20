# frozen_string_literal: true

module OrderNavHelper
  def order_nav_link(title, path, state)
    content_tag(:li, class: "nav-item") do
      link_to_if(
        state != :disabled,
        title,
        path,
        class: "nav-link #{"active" if state == :active}",
        "data-probe": "",
        onclick:
          if state == :next
            go_to_next_step
          else
            ""
          end
      ) do
        if state == :active
          content_tag(
            :a,
            title,
            class: "nav-link",
            href: "#",
            onclick: "document.getElementById('order-form').submit();"
          )
        else
          content_tag(:div, title, class: "nav-link disabled")
        end
      end
    end
  end

  def go_to_next_step
    "
                      const form = document.getElementById('order-form');
                      if (typeof(form) != 'undefined' && form != null) {
                        form.submit();
                      }
                    "
  end
end
