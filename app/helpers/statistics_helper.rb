# frozen_string_literal: true

module StatisticsHelper
  def statistics_description(type)
    case type
    when "fully_open_access"
      _(
        "Number of services with at least one fully open access offer. <br><br>" +
          "Fully open access: no ordering procedure is necessary to access " +
          "the service and no user authentication is required."
      )
    when "open_access"
      _(
        "Number of services with at least one open access offer. <br><br>" +
          "Open access: no ordering procedure is necessary to access the service but it requires user authentication."
      )
    when "order_required"
      _(
        "Number of services with at least one offer requiring ordering. <br><br>" +
          "Request/Order required: accessing the service requires an ordering procedure."
      )
    else
      _("Number of services with at least one other offer.")
    end
  end
end
