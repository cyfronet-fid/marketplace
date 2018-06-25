# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
  include Sentryable
  include Pundit

  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_back fallback_location: root_path,
                  alert: "You are not authorized to see this page"
  end
end
