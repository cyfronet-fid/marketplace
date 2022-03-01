# frozen_string_literal: true

module TourHelper
  def tour(tour, show_welcome_modal)
    if tour.present? || show_welcome_modal
      data = {
        is_logged_in: !current_user.nil?,
        show_welcome_modal: show_welcome_modal,
        tour_controller_action: action_name,
        tour_controller_name: controller_name,
        controller_name: controller_name,
        action_name: action_name,
        form_authenticity_token: form_authenticity_token,
        buttons_labels: {
          take_tour: t("tours.taketour"),
          later: t("tours.later"),
          skip: t("tours.skip"),
          continue: t("tours.continue"),
          go_to_feedback: t("tours.gotofeedback"),
          done: t("tours.done"),
          next: t("tours.next"),
          exit: t("tours.exit")
        }
      }
      if tour.present?
        tour_name = tour[:name]
        tour_content = tour[:content]

        activation_strategy = tour_content["activation_strategy"] || "default"

        data =
          data.merge(
            {
              activation_strategy: activation_strategy,
              tour_name: tour_name,
              steps:
                tour_content["steps"].values.map do |step|
                  { **step.transform_keys(&:to_sym), text: markdown(step["text"]) }
                end,
              feedback: tour_content["feedback"]
            }
          )

        if activation_strategy == "default"
          data =
            data.merge(
              {
                cookies_names: {
                  skip: "tours-marketplace-#{controller_name}-#{action_name}-#{tour_name}",
                  completed: "tours-marketplace-#{controller_name}-#{action_name}-completed"
                }
              }
            )
        end

        if tour_content["next"].present?
          next_tour = tour_content["next"]
          data =
            data.merge(
              {
                next_tour_link:
                  next_tour_link(
                    next_tour["redirect_to"],
                    next_tour["controller_params"] || {},
                    next_tour["controller_params_map"] || {}
                  )
              }
            )
        end
      end

      render(partial: "layouts/tour", locals: { data: data })
    end
  end

  def next_tour_link(next_tour_path, controller_params, controller_params_map)
    mapped_params = controller_params_map.to_h { |param_id, mapped_id| [mapped_id.to_sym, controller.params[param_id]] }
    params = mapped_params.merge(controller_params)
    next_tour_path.blank? ? nil : send(next_tour_path, params).to_s
  end
end
