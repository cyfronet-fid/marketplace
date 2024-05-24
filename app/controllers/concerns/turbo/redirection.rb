# frozen_string_literal: true

module Turbo::Redirection
  extend ActiveSupport::Concern

  def redirect_to(url = {}, options = {})
    turbo = options.delete(:turbo)

    super.tap { visit_location_with_turbo(url, turbo) if turbo != false && request.xhr? && !request.get? }
  end

  private

  def visit_location_with_turbo(location, action)
    visit_options = { action: action.to_s == "advance" ? action : "replace" }

    script = []
    script << "Turbo.cache.clear()"
    script << "Turbo.visit(#{location.to_json}, #{visit_options.to_json})"

    self.status = 200
    self.response_body = script.join("\n")
    response.content_type = "text/javascript"
    response.headers["X-Xhr-Redirect"] = location
  end
end
